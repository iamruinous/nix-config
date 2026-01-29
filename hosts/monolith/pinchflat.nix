# Pinchflat lifecycle webhook module
#
# Generates a lifecycle script for Pinchflat that sends media_downloaded
# events to an n8n webhook for YouTube summary processing.
#
# Filtering can be done by either:
#   - allowedProfiles: List of Pinchflat media profile names (recommended)
#   - allowedChannels: List of Pinchflat source collection names (channel names)
#
# Using allowedProfiles is preferred because profiles are configured once in
# Pinchflat and can be assigned to multiple sources, avoiding the need to
# update this config when adding new channels.
#
# Usage:
#   services.pinchflat-lifecycle = {
#     enable = true;
#     webhookUrl = "https://n8h.meskill.farm/webhook/youtube-summary";
#     # Recommended: filter by media profile
#     allowedProfiles = [ "Summarize" ];
#     # OR filter by channel name (legacy)
#     # allowedChannels = [ "PBS NewsHour" "CNN" ];
#   };
#
# ============================================================================
# LIFECYCLE EVENT DATA REFERENCE
# ============================================================================
# The lifecycle script receives a JSON payload with the following structure.
# This is the MediaItem struct with source and media_profile associations.
#
# MediaItem fields (root level):
#   id                    - Internal database ID
#   uuid                  - UUID for public URLs (prevents enumeration)
#   title                 - Video title
#   media_id              - YouTube video ID
#   description           - Video description
#   original_url          - Original YouTube URL
#   livestream            - Boolean: is this a livestream?
#   short_form_content    - Boolean: is this a YouTube Short?
#   media_downloaded_at   - UTC datetime when downloaded
#   media_redownloaded_at - UTC datetime of quality upgrade (if any)
#   uploaded_at           - UTC datetime when uploaded to YouTube
#   upload_date_index     - Index for ordering within same upload date
#   duration_seconds      - Video duration in seconds
#   playlist_index        - Position in playlist (0 for channels)
#   predicted_media_filepath - Expected filepath before download
#   media_filepath        - Actual filepath after download
#   media_size_bytes      - File size in bytes
#   thumbnail_filepath    - Path to thumbnail image
#   metadata_filepath     - Path to metadata JSON
#   nfo_filepath          - Path to NFO file
#   subtitle_filepaths    - Array of [language, filepath] pairs
#   last_error            - Last error message (if any)
#   prevent_download      - Boolean: prevent future downloads?
#   prevent_culling       - Boolean: prevent automatic deletion?
#   culled_at             - UTC datetime when culled
#   inserted_at           - Record creation time
#   updated_at            - Record update time
#
# Source fields (nested under "source"):
#   id                    - Internal database ID
#   uuid                  - UUID for public URLs
#   enabled               - Boolean: is source active?
#   custom_name           - User-defined name for source
#   collection_name       - YouTube channel/playlist name
#   collection_id         - YouTube channel/playlist ID
#   collection_type       - "channel" or "playlist"
#   description           - Source description
#   original_url          - YouTube channel/playlist URL
#   index_frequency_minutes - How often to check for new videos
#   fast_index            - Boolean: use fast indexing?
#   download_media        - Boolean: download videos?
#   last_indexed_at       - Last index time
#   download_cutoff_date  - Only download videos after this date
#   retention_period_days - Auto-delete after N days
#   title_filter_regex    - Regex to filter video titles
#   series_directory      - Output directory path
#   media_profile_id      - ID of associated media profile
#   output_path_template_override - Custom output path template
#   min_duration_seconds  - Minimum video duration filter
#   max_duration_seconds  - Maximum video duration filter
#   inserted_at           - Record creation time
#   updated_at            - Record update time
#
# MediaProfile fields (nested under "source.media_profile"):
#   id                    - Internal database ID
#   name                  - Profile name (e.g., "Summarize", "Archive")
#   output_path_template  - Default output path template
#   download_subs         - Boolean: download subtitles?
#   download_auto_subs    - Boolean: download auto-generated subs?
#   embed_subs            - Boolean: embed subs in video?
#   sub_langs             - Subtitle language codes
#   download_thumbnail    - Boolean: download thumbnail?
#   embed_thumbnail       - Boolean: embed thumbnail in video?
#   download_source_images - Boolean: download channel art?
#   download_metadata     - Boolean: download metadata JSON?
#   embed_metadata        - Boolean: embed metadata in video?
#   download_nfo          - Boolean: download NFO file?
#   sponsorblock_behaviour - "disabled", "mark", or "remove"
#   sponsorblock_categories - Array of SponsorBlock categories
#   shorts_behaviour      - "include", "exclude", or "only"
#   livestream_behaviour  - "include", "exclude", or "only"
#   audio_track           - Preferred audio track
#   preferred_resolution  - "4320p", "2160p", "1440p", "1080p", etc.
#   media_container       - Output container format
#   redownload_delay_days - Days before quality upgrade attempt
#   inserted_at           - Record creation time
#   updated_at            - Record update time
#
# Example JSON payload structure:
# {
#   "id": 123,
#   "title": "Video Title",
#   "media_id": "dQw4w9WgXcQ",
#   "media_filepath": "/downloads/Channel/2024-01-15 Video Title/...",
#   "subtitle_filepaths": [["en", "/path/to/subs.en.vtt"]],
#   "duration_seconds": 300,
#   "source": {
#     "collection_name": "PBS NewsHour",
#     "media_profile": {
#       "name": "Summarize",
#       "download_subs": true
#     }
#   }
# }
# ============================================================================
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pinchflat-lifecycle;

  # Determine which filter mode to use
  # Priority: allowedProfiles > allowedChannels > no filter
  hasProfileFilter = cfg.allowedProfiles != [];
  hasChannelFilter = cfg.allowedChannels != [];

  # Generate the bash array and check function for allowed profiles
  profilesArray =
    if hasProfileFilter
    then ''
      # Allowed media profiles for transcript processing
      ALLOWED_PROFILES=(
      ${concatMapStringsSep "\n" (p: "  \"${p}\"") cfg.allowedProfiles}
      )

      # Check if media profile is in the allowed list
      is_allowed_profile() {
        local profile="$1"
        for allowed in "''${ALLOWED_PROFILES[@]}"; do
          if [[ "$profile" == "$allowed" ]]; then
            return 0
          fi
        done
        return 1
      }
    ''
    else "";

  # Generate the bash array of allowed channels (legacy)
  channelsArray =
    if hasChannelFilter && !hasProfileFilter
    then ''
      # Allowed channels for transcript processing (legacy mode)
      ALLOWED_CHANNELS=(
      ${concatMapStringsSep "\n" (ch: "  \"${ch}\"") cfg.allowedChannels}
      )

      # Check if channel is in the allowed list
      is_allowed_channel() {
        local channel="$1"
        for allowed in "''${ALLOWED_CHANNELS[@]}"; do
          if [[ "$channel" == "$allowed" ]]; then
            return 0
          fi
        done
        return 1
      }
    ''
    else "";

  # Generate the filter check logic
  filterCheckLogic =
    if hasProfileFilter
    then ''

      # Check if this media profile is in the allowed list
      if ! is_allowed_profile "$MEDIA_PROFILE"; then
        log "Media profile '$MEDIA_PROFILE' not in allowed list - skipping"
        exit 0
      fi
    ''
    else if hasChannelFilter
    then ''

      # Check if this channel is in the allowed list
      if ! is_allowed_channel "$CHANNEL"; then
        log "Channel '$CHANNEL' not in allowed list - skipping"
        exit 0
      fi
    ''
    else "";

  # Generate the lifecycle script
  # NOTE: Uses plain commands (jq, curl, awk) since this runs INSIDE the Pinchflat container
  # which has these tools at /usr/bin/, not Nix store paths
  lifecycleScript = pkgs.writeTextFile {
    name = "pinchflat-lifecycle";
    executable = true;
    text = ''
      #!/bin/bash
      # Pinchflat lifecycle script for YouTube summary processing
      # Sends media_downloaded events to n8n for transcript extraction and summarization
      #
      # Events: app_init, media_pre_download, media_downloaded, media_deleted
      # This script only handles media_downloaded events with subtitles.
      #
      # Generated by: nix-config (hosts/monolith/pinchflat.nix)
      # Target: n8n workflow "YouTube Summary"

      set -euo pipefail

      EVENT_TYPE="''${1:-}"
      EVENT_DATA="''${2:-}"

      # Webhook endpoint for n8n
      WEBHOOK_URL="${cfg.webhookUrl}"

      ${profilesArray}${channelsArray}

      # Logging helper
      log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [lifecycle] $1"
      }

      # Parse SRT/VTT file with deduplication of consecutive lines
      # Removes timestamps, indices, tags, and deduplicates overlapping subtitle text
      parse_srt() {
        awk '
          BEGIN { prev = ""; result = "" }
          {
            gsub(/\r/, "")
            gsub(/^[ \t]+|[ \t]+$/, "")
            if ($0 == "") next
            if ($0 == "WEBVTT") next
            if ($0 ~ /^[0-9]+$/) next
            if ($0 ~ /-->/) next
            if ($0 ~ /^NOTE/) next
            if ($0 ~ /^STYLE/) next
            gsub(/<[^>]*>/, "")
            gsub(/\{[^}]*\}/, "")
            gsub(/^[ \t]+|[ \t]+$/, "")
            if ($0 == "") next
            if ($0 != prev) {
              if (result != "") result = result " " $0
              else result = $0
              prev = $0
            }
          }
          END { print result }
        ' "$1"
      }

      # Only process media_downloaded events
      if [[ "$EVENT_TYPE" != "media_downloaded" ]]; then
        exit 0
      fi

      # Validate we have event data
      if [[ -z "$EVENT_DATA" ]]; then
        log "ERROR: No event data received"
        exit 0
      fi

      # Extract metadata from event data
      TITLE=$(echo "$EVENT_DATA" | jq -r '.title // "unknown"')
      CHANNEL=$(echo "$EVENT_DATA" | jq -r '.source.collection_name // "unknown"')
      MEDIA_PROFILE=$(echo "$EVENT_DATA" | jq -r '.source.media_profile.name // "unknown"')
      VIDEO_ID=$(echo "$EVENT_DATA" | jq -r '.media_id // "unknown"')
      VIDEO_FILEPATH=$(echo "$EVENT_DATA" | jq -r '.media_filepath // ""')
      DESCRIPTION=$(echo "$EVENT_DATA" | jq -r '.description // ""')
      ORIGINAL_URL=$(echo "$EVENT_DATA" | jq -r '.original_url // .webpage_url // ""')
      UPLOAD_DATE=$(echo "$EVENT_DATA" | jq -r '.uploaded_at // ""')
      DURATION_SECONDS=$(echo "$EVENT_DATA" | jq -r '.duration_seconds // 0')

      # Try to find subtitle file
      SUBTITLE_FILE=""

      # First try subtitle_filepaths from event data
      SUBTITLE_COUNT=$(echo "$EVENT_DATA" | jq -r '.subtitle_filepaths | if type == "array" then length else 0 end // 0')
      if [[ "$SUBTITLE_COUNT" -gt 0 ]]; then
        CANDIDATE=$(echo "$EVENT_DATA" | jq -r '.subtitle_filepaths[0] // ""')
        if [[ -n "$CANDIDATE" ]] && [[ -f "$CANDIDATE" ]]; then
          SUBTITLE_FILE="$CANDIDATE"
          log "Found subtitle in event data: $SUBTITLE_FILE"
        else
          log "Event data subtitle path invalid or missing: $CANDIDATE"
        fi
      fi

      # Fallback: Look for .srt file next to the video file
      if [[ -z "$SUBTITLE_FILE" ]] && [[ -n "$VIDEO_FILEPATH" ]]; then
        VIDEO_DIR=$(dirname "$VIDEO_FILEPATH")
        VIDEO_BASE=$(basename "$VIDEO_FILEPATH")
        VIDEO_NAME="''${VIDEO_BASE%.*}"

        # Search for .en.srt or .srt file matching the video name
        if [[ -f "$VIDEO_DIR/$VIDEO_NAME.en.srt" ]]; then
          SUBTITLE_FILE="$VIDEO_DIR/$VIDEO_NAME.en.srt"
          log "Found subtitle on disk: $SUBTITLE_FILE"
        elif [[ -f "$VIDEO_DIR/$VIDEO_NAME.srt" ]]; then
          SUBTITLE_FILE="$VIDEO_DIR/$VIDEO_NAME.srt"
          log "Found subtitle on disk: $SUBTITLE_FILE"
        else
          # Try to find any .srt file with matching prefix
          FOUND_SRT=$(find "$VIDEO_DIR" -maxdepth 1 -name "$VIDEO_NAME*.srt" -type f 2>/dev/null | head -n1)
          if [[ -n "$FOUND_SRT" ]]; then
            SUBTITLE_FILE="$FOUND_SRT"
            log "Found subtitle on disk (pattern match): $SUBTITLE_FILE"
          fi
        fi
      fi

      # Skip if no subtitle found
      if [[ -z "$SUBTITLE_FILE" ]] || [[ ! -f "$SUBTITLE_FILE" ]]; then
        log "No subtitles available for: $TITLE - skipping"
        exit 0
      fi
      ${filterCheckLogic}

      log "Processing: $TITLE (profile: $MEDIA_PROFILE, channel: $CHANNEL, video_id: $VIDEO_ID)"

      # Parse and deduplicate transcript
      TRANSCRIPT_TEXT=$(parse_srt "$SUBTITLE_FILE")
      TRANSCRIPT_LENGTH=''${#TRANSCRIPT_TEXT}

      if [[ "$TRANSCRIPT_LENGTH" -eq 0 ]]; then
        log "WARNING: Parsed transcript is empty for: $TITLE - skipping"
        exit 0
      fi

      log "Extracted transcript: $TRANSCRIPT_LENGTH characters (deduplicated)"

      # Build payload with all required fields for n8n YouTube Summary workflow
      PAYLOAD=$(jq -n \
        --arg title "$TITLE" \
        --arg media_id "$VIDEO_ID" \
        --arg media_filepath "$VIDEO_FILEPATH" \
        --arg subtitle_filepath "$SUBTITLE_FILE" \
        --arg transcript "$TRANSCRIPT_TEXT" \
        --arg channel "$CHANNEL" \
        --arg description "$DESCRIPTION" \
        --arg original_url "$ORIGINAL_URL" \
        --arg upload_date "$UPLOAD_DATE" \
        --argjson duration "$DURATION_SECONDS" \
        '{
          title: $title,
          media_id: $media_id,
          media_filepath: $media_filepath,
          subtitle_filepaths: [$subtitle_filepath],
          subtitle_filepath: $subtitle_filepath,
          transcript_text: $transcript,
          duration_seconds: $duration,
          description: $description,
          original_url: $original_url,
          upload_date: $upload_date,
          source: {collection_name: $channel}
        }')

      # Send to n8n webhook
      RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -H "X-Pinchflat-Event: media_downloaded" \
        --max-time 60 \
        -d "$PAYLOAD" 2>&1) || true

      # Extract HTTP status code (last line)
      HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
      BODY=$(echo "$RESPONSE" | sed '$d')

      if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "201" ]] || [[ "$HTTP_CODE" == "202" ]]; then
        log "SUCCESS: Sent to n8n (HTTP $HTTP_CODE) - $BODY"
      else
        log "WARNING: n8n returned HTTP $HTTP_CODE - $BODY"
        # Don't fail - Pinchflat should continue even if webhook fails
      fi

      exit 0
    '';
  };
in {
  options.services.pinchflat-lifecycle = {
    enable = mkEnableOption "Pinchflat lifecycle webhook for YouTube summary processing";

    webhookUrl = mkOption {
      type = types.str;
      default = "https://n8h.meskill.farm/webhook/youtube-summary";
      description = "Webhook URL to send media_downloaded events to";
      example = "https://n8n.example.com/webhook/youtube-summary";
    };

    allowedProfiles = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of Pinchflat media profile names to process for transcription.
        Only videos from sources using these profiles will trigger the webhook.
        This is the recommended filtering method - create a "Summarize" profile
        in Pinchflat and assign it to sources you want summarized.
        Takes precedence over allowedChannels if both are set.
        If empty (and allowedChannels is empty), ALL videos will be processed.
      '';
      example = ["Summarize"];
    };

    allowedChannels = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        (Legacy) List of Pinchflat collection names (channel names) to process.
        Only videos from these channels will trigger the webhook.
        Consider using allowedProfiles instead for easier maintenance.
        Ignored if allowedProfiles is set.
        If empty (and allowedProfiles is empty), ALL channels will be processed.
      '';
      example = [
        "PBS NewsHour"
        "CNN"
        "BBC News"
      ];
    };

    scriptPath = mkOption {
      type = types.path;
      default = lifecycleScript;
      readOnly = true;
      description = "Path to the generated lifecycle script (read-only)";
    };
  };

  config = mkIf cfg.enable {
    # Make the script available as a derivation output
    # The container definition can reference cfg.scriptPath
  };
}
