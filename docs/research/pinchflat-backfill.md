# Pinchflat Transcript Backfill

This document explains how to backfill existing Pinchflat videos through the YouTube Summary n8n workflow.

## Background

The Pinchflat lifecycle script (`hosts/monolith/pinchflat.nix`) automatically sends newly downloaded videos to the n8n YouTube Summary workflow. However, videos downloaded before the lifecycle script was configured need to be manually backfilled.

## Why Backfill is Needed

1. **Lifecycle script only triggers on new downloads** - Existing videos in `/nas/media/YT/` were downloaded before the webhook integration existed
2. **SRT subtitle deduplication** - YouTube auto-generated subtitles have overlapping text segments that need deduplication before sending to n8n
3. **Missing metadata** - The backfill script extracts metadata from `.info.json` files that Pinchflat's event data may not include

## SRT Deduplication

YouTube auto-generated subtitles (SRT/VTT format) contain overlapping text for smooth display:

```
1
00:00:00,080 --> 00:00:01,750
You know, the joke is the peak of

2
00:00:01,750 --> 00:00:01,760
You know, the joke is the peak of
 
3
00:00:01,760 --> 00:00:03,510
You know, the joke is the peak of
venture capital is when you get excited
```

Without deduplication, the transcript would contain massive redundancy. The backfill script uses AWK to:
1. Strip timestamps, indices, and formatting tags
2. Remove consecutive duplicate lines
3. Join into a single clean transcript

## Webhook Payload

The n8n YouTube Summary workflow expects these fields:

| Field | Source | Required |
|-------|--------|----------|
| `title` | info.json | Yes |
| `media_id` | info.json (.id) | Yes |
| `transcript_text` | Parsed SRT | Yes |
| `duration_seconds` | info.json | Yes |
| `original_url` | info.json (.webpage_url) | Yes (for Discord) |
| `description` | info.json | No |
| `upload_date` | info.json | No |
| `source.collection_name` | Channel name | Yes |

## Backfill Script

The script processes all `.mp4` files in a directory, finds matching `.en.srt` or `.srt` files, parses the transcript with deduplication, and sends to the webhook.

```bash
#!/usr/bin/env bash
# Pinchflat Transcript Backfill Script
#
# Usage: bash backfill.sh
# 
# Configure BASE_DIR and WEBHOOK_URL before running.

WEBHOOK_URL="https://n8h.meskill.farm/webhook/youtube-summary"
CHANNEL="AI News & Strategy Daily | Nate B Jones"
BASE_DIR="/nas/media/YT/AI News & Strategy Daily # Nate B Jones/Season 2026"

log() { echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1"; }

# Parse SRT with consecutive line deduplication
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

count=0
total=$(find "$BASE_DIR" -name "*.mp4" | wc -l)
log "Found $total videos to process"

find "$BASE_DIR" -name "*.mp4" -print | sort | while read -r video_file; do
  count=$((count + 1))
  video_dir=$(dirname "$video_file")
  video_base=$(basename "$video_file")
  video_name="${video_base%.*}"
  
  # Find subtitle file
  subtitle_file=""
  [[ -f "$video_dir/$video_name.en.srt" ]] && subtitle_file="$video_dir/$video_name.en.srt"
  [[ -z "$subtitle_file" && -f "$video_dir/$video_name.srt" ]] && subtitle_file="$video_dir/$video_name.srt"
  
  if [[ -z "$subtitle_file" ]]; then
    log "[$count/$total] SKIP (no srt): $video_name"
    continue
  fi
  
  # Extract metadata from info.json
  info_file="$video_dir/$video_name.info.json"
  video_id=$(jq -r '.id // "unknown"' "$info_file" 2>/dev/null)
  title=$(jq -r '.title // ""' "$info_file" 2>/dev/null)
  [[ -z "$title" ]] && title="$video_name"
  duration_seconds=$(jq -r '.duration // 0' "$info_file" 2>/dev/null)
  description=$(jq -r '.description // ""' "$info_file" 2>/dev/null)
  original_url=$(jq -r '.original_url // .webpage_url // ""' "$info_file" 2>/dev/null)
  upload_date=$(jq -r '.upload_date // ""' "$info_file" 2>/dev/null)
  
  # Parse and deduplicate transcript
  transcript_text=$(parse_srt "$subtitle_file")
  transcript_length=${#transcript_text}
  
  if [[ "$transcript_length" -eq 0 ]]; then
    log "[$count/$total] SKIP (empty): $title"
    continue
  fi
  
  log "[$count/$total] Processing: $title ($transcript_length chars)"
  
  # Build payload
  payload=$(jq -n \
    --arg title "$title" \
    --arg media_id "$video_id" \
    --arg media_filepath "$video_file" \
    --arg subtitle_filepath "$subtitle_file" \
    --arg transcript "$transcript_text" \
    --arg channel "$CHANNEL" \
    --arg description "$description" \
    --arg original_url "$original_url" \
    --arg upload_date "$upload_date" \
    --argjson duration "$duration_seconds" \
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
  
  # Send to webhook
  response=$(curl -s -w "\n%{http_code}" -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -H "X-Pinchflat-Event: media_downloaded" \
    --max-time 60 \
    -d "$payload" 2>/dev/null)
  
  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')
  
  if [[ "$http_code" =~ ^20[012]$ ]]; then
    log "[$count/$total] SUCCESS (HTTP $http_code) - $body"
  else
    log "[$count/$total] FAILED (HTTP $http_code) - $body"
  fi
  
  # Rate limit - 2 second delay between requests
  sleep 2
done

log "Backfill complete"
```

## Usage

1. SSH to monolith: `ssh monolith.meskill.farm`
2. Save the script: `cat > /tmp/backfill.sh` (paste script, Ctrl+D)
3. Make executable: `chmod +x /tmp/backfill.sh`
4. Edit `BASE_DIR` and `CHANNEL` for your target
5. Run: `bash /tmp/backfill.sh`

### Examples

**Single channel, specific season:**
```bash
BASE_DIR="/nas/media/YT/AI News & Strategy Daily # Nate B Jones/Season 2026"
CHANNEL="AI News & Strategy Daily | Nate B Jones"
```

**Entire channel (all seasons):**
```bash
BASE_DIR="/nas/media/YT/AI News & Strategy Daily # Nate B Jones"
CHANNEL="AI News & Strategy Daily | Nate B Jones"
```

**Different channel:**
```bash
BASE_DIR="/nas/media/YT/Veritasium"
CHANNEL="Veritasium"
```

## Testing Single Video

To test a single video before batch processing:

```bash
# Extract and display payload without sending
video_file="/path/to/video.mp4"
# ... (use parse_srt function and jq to build payload)
echo "$payload" | jq .

# Or send to webhook with verbose output
curl -v -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "X-Pinchflat-Event: media_downloaded" \
  -d "$payload"
```

## Related

- **Lifecycle script**: `hosts/monolith/pinchflat.nix` - Handles new downloads automatically
- **Configuration**: `hosts/monolith/configuration.nix` - Sets webhook URL and allowed channels
- **n8n workflow**: YouTube Summary workflow at `n8h.meskill.farm`
