# ruinous.vdirsyncer.enable = true;
#
# Manages vdirsyncer (CalDAV/CardDAV sync) with:
# - Encrypted config synced via agenix-rekey
# - Optional OAuth token sync for Google Calendar
# - Three-phase sync: discover → metasync → sync
# - Automatic sync via systemd timers (Linux) or launchd (macOS)
# - Auto-repair on sync failures (stale references, deleted events)
# - khal calendar CLI integration
#
# Systemd service architecture (Linux):
# - vdirsyncer-discover: First-run collection discovery (creates marker file)
# - vdirsyncer-metasync: Weekly metadata refresh (depends on discover)
# - vdirsyncer-sync: Regular sync every 15 minutes (depends on discover)
#
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.vdirsyncer;
  khal_config = ../../../files/configs/khal/config;

  # Marker file indicating discover has been run successfully
  stateDir = "${config.home.homeDirectory}/.local/state/vdirsyncer";
  cacheDir = "${config.home.homeDirectory}/.cache/vdirsyncer";
  discoverMarker = "${stateDir}/.discovered";

  # Wrapper script for discover that auto-answers "yes" to prompts
  discoverScript = pkgs.writeShellScript "vdirsyncer-discover" ''
    set -euo pipefail
    mkdir -p "${stateDir}"

    echo "Starting vdirsyncer discovery at $(date)"

    # Auto-answer "yes" to all collection creation prompts
    # In future vdirsyncer versions, use 'implicit = "create"' in config instead
    if yes | ${pkgs.vdirsyncer}/bin/vdirsyncer discover; then
      # Create marker file on success
      touch "${discoverMarker}"
      echo "Discovery complete at $(date)" >> "${discoverMarker}"
      echo "Discovery completed successfully"
    else
      echo "Discovery completed with warnings (this is often normal)"
      touch "${discoverMarker}"
      echo "Discovery complete at $(date)" >> "${discoverMarker}"
    fi
  '';

  # Robust sync script with auto-repair on failure
  syncScript = pkgs.writeShellScript "vdirsyncer-sync" ''
    set -euo pipefail
    mkdir -p "${stateDir}"
    mkdir -p "${cacheDir}"

    echo "Starting vdirsyncer sync at $(date)"

    # Try sync first
    if ${pkgs.vdirsyncer}/bin/vdirsyncer sync 2>"${cacheDir}/sync-error.log"; then
      echo "Sync completed successfully at $(date)"
      exit 0
    fi

    # Sync failed - check if it's a repairable error
    sync_error=$(cat "${cacheDir}/sync-error.log" 2>/dev/null || echo "")

    if echo "$sync_error" | grep -qE "(NotFoundError|Unknown error occurred|properties are missing)"; then
      echo "Sync failed with repairable error. Attempting auto-repair..."

      # Extract the failing collection from the error message
      # Error format: "error: Unknown error occurred for <pair>/<collection>: ..."
      failing_collections=$(echo "$sync_error" | grep -oE "for [^:]+:" | sed 's/for //g; s/:$//g' | sort -u)

      if [[ -n "$failing_collections" ]]; then
        echo "Repairing collections: $failing_collections"

        # Repair each failing collection
        while IFS= read -r collection; do
          if [[ -n "$collection" ]]; then
            # Parse pair and collection - format is "pair/collection"
            pair=$(echo "$collection" | cut -d'/' -f1)
            coll_id=$(echo "$collection" | cut -d'/' -f2-)

            # Try repairing both local and remote storages
            echo "Repairing $${pair}_remote/$coll_id..."
            yes | ${pkgs.vdirsyncer}/bin/vdirsyncer repair "$${pair}_remote/$coll_id" 2>/dev/null || true

            echo "Repairing $${pair}_local/$coll_id..."
            yes | ${pkgs.vdirsyncer}/bin/vdirsyncer repair "$${pair}_local/$coll_id" 2>/dev/null || true
          fi
        done <<< "$failing_collections"

        echo "Repair complete. Retrying sync..."

        # Retry sync after repair
        if ${pkgs.vdirsyncer}/bin/vdirsyncer sync; then
          echo "Sync completed successfully after repair at $(date)"
          exit 0
        else
          echo "Sync still failing after repair. Manual intervention may be required." >&2
          exit 1
        fi
      else
        echo "Could not identify failing collections. Manual repair may be required." >&2
        cat "${cacheDir}/sync-error.log" >&2
        exit 1
      fi
    else
      # Non-repairable error
      echo "Sync failed with non-repairable error:" >&2
      cat "${cacheDir}/sync-error.log" >&2
      exit 1
    fi
  '';

  # Wrapper script for macOS that handles all phases with error recovery
  darwinSyncScript = pkgs.writeShellScript "vdirsyncer-sync-all" ''
    set -euo pipefail
    mkdir -p "${stateDir}"
    mkdir -p "${cacheDir}"

    echo "=== vdirsyncer sync started at $(date) ==="

    # Run discover if marker doesn't exist
    if [[ ! -f "${discoverMarker}" ]]; then
      echo "Running initial discovery..."
      if yes | ${pkgs.vdirsyncer}/bin/vdirsyncer discover; then
        touch "${discoverMarker}"
        echo "Discovery complete at $(date)" >> "${discoverMarker}"
      else
        echo "Discovery completed with warnings"
        touch "${discoverMarker}"
        echo "Discovery complete at $(date)" >> "${discoverMarker}"
      fi
    fi

    # Run metasync weekly (check marker file age)
    metasync_marker="${stateDir}/.last_metasync"
    if [[ ! -f "$metasync_marker" ]] || [[ $(find "$metasync_marker" -mtime +7 2>/dev/null) ]]; then
      echo "Running weekly metasync..."
      ${pkgs.vdirsyncer}/bin/vdirsyncer metasync || true
      touch "$metasync_marker"
    fi

    # Run sync with auto-repair on failure
    echo "Running sync..."
    if ${pkgs.vdirsyncer}/bin/vdirsyncer sync 2>"${cacheDir}/sync-error.log"; then
      echo "Sync completed successfully at $(date)"
      exit 0
    fi

    # Sync failed - check if it's a repairable error
    sync_error=$(cat "${cacheDir}/sync-error.log" 2>/dev/null || echo "")

    if echo "$sync_error" | grep -qE "(NotFoundError|Unknown error occurred|properties are missing)"; then
      echo "Sync failed with repairable error. Attempting auto-repair..."

      # Extract the failing collection from the error message
      failing_collections=$(echo "$sync_error" | grep -oE "for [^:]+:" | sed 's/for //g; s/:$//g' | sort -u)

      if [[ -n "$failing_collections" ]]; then
        echo "Repairing collections: $failing_collections"

        while IFS= read -r collection; do
          if [[ -n "$collection" ]]; then
            pair=$(echo "$collection" | cut -d'/' -f1)
            coll_id=$(echo "$collection" | cut -d'/' -f2-)

            echo "Repairing $${pair}_remote/$coll_id..."
            yes | ${pkgs.vdirsyncer}/bin/vdirsyncer repair "$${pair}_remote/$coll_id" 2>/dev/null || true

            echo "Repairing $${pair}_local/$coll_id..."
            yes | ${pkgs.vdirsyncer}/bin/vdirsyncer repair "$${pair}_local/$coll_id" 2>/dev/null || true
          fi
        done <<< "$failing_collections"

        echo "Repair complete. Retrying sync..."

        if ${pkgs.vdirsyncer}/bin/vdirsyncer sync; then
          echo "Sync completed successfully after repair at $(date)"
          exit 0
        else
          echo "Sync still failing after repair"
          exit 1
        fi
      fi
    fi

    echo "Sync failed:"
    cat "${cacheDir}/sync-error.log"
    exit 1
  '';
in {
  options.ruinous.vdirsyncer = {
    enable = mkEnableOption "vdirsyncer CalDAV/CardDAV sync with khal integration";

    syncCredentials = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to sync OAuth credentials (Google token) via agenix-rekey.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Linux: systemd services and timers for three-phase sync
    (mkIf pkgs.stdenv.isLinux {
      # ═══════════════════════════════════════════════════════════════════════
      # Phase 1: Discovery Service
      # Runs once on first boot (if marker doesn't exist) or manually
      # Auto-answers "yes" to collection creation prompts
      # ═══════════════════════════════════════════════════════════════════════
      systemd.user.services.vdirsyncer-discover = {
        Unit = {
          Description = "vdirsyncer collection discovery";
          Documentation = "man:vdirsyncer(1)";
          # Don't run if already discovered
          ConditionPathExists = "!${discoverMarker}";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${discoverScript}";
          # Ensure state directory exists
          StateDirectory = "vdirsyncer";
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };

      # ═══════════════════════════════════════════════════════════════════════
      # Phase 2: Metasync Service + Timer
      # Refreshes collection metadata weekly
      # ═══════════════════════════════════════════════════════════════════════
      systemd.user.services.vdirsyncer-metasync = {
        Unit = {
          Description = "vdirsyncer metadata sync";
          Documentation = "man:vdirsyncer(1)";
          # Only run if discover has completed
          ConditionPathExists = "${discoverMarker}";
          # Ensure discover runs first if needed
          Wants = ["vdirsyncer-discover.service"];
          After = ["vdirsyncer-discover.service"];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer metasync";
        };
      };

      systemd.user.timers.vdirsyncer-metasync = {
        Unit = {
          Description = "vdirsyncer weekly metadata sync";
        };
        Timer = {
          # Run weekly on Sunday at 3am
          OnCalendar = "Sun *-*-* 03:00:00";
          # Run on boot if last run was missed
          Persistent = true;
          # Randomize to avoid thundering herd
          RandomizedDelaySec = "1h";
        };
        Install = {
          WantedBy = ["timers.target"];
        };
      };

      # ═══════════════════════════════════════════════════════════════════════
      # Phase 3: Sync Service + Timer
      # Regular calendar/contact sync every 15 minutes
      # Includes auto-repair on common sync failures
      # ═══════════════════════════════════════════════════════════════════════
      systemd.user.services.vdirsyncer-sync = {
        Unit = {
          Description = "vdirsyncer calendar and contact sync";
          Documentation = "man:vdirsyncer(1)";
          # Only run if discover has completed
          ConditionPathExists = "${discoverMarker}";
          # Ensure discover runs first if needed
          Wants = ["vdirsyncer-discover.service"];
          After = ["vdirsyncer-discover.service" "network-online.target"];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${syncScript}";
        };
      };

      systemd.user.timers.vdirsyncer-sync = {
        Unit = {
          Description = "vdirsyncer periodic sync";
        };
        Timer = {
          # Start 1 minute after boot
          OnBootSec = "1m";
          # Then every 15 minutes after last run
          OnUnitInactiveSec = "15m";
          # Catch up if timer was missed
          Persistent = true;
        };
        Install = {
          WantedBy = ["timers.target"];
        };
      };
    })

    # macOS: launchd agent with wrapper script handling all phases
    (mkIf pkgs.stdenv.isDarwin {
      launchd.agents.vdirsyncer = {
        enable = true;
        config = {
          ProgramArguments = ["${darwinSyncScript}"];
          # Run every 15 minutes (900 seconds)
          StartInterval = 900;
          # Run immediately on load
          RunAtLoad = true;
          # Log output for debugging
          StandardOutPath = "${cacheDir}/launchd-stdout.log";
          StandardErrorPath = "${cacheDir}/launchd-stderr.log";
        };
      };
    })

    # Core configuration (always enabled)
    {
      home.packages = [
        pkgs.vdirsyncer
      ];

      # Encrypted vdirsyncer config
      age.secrets.vdirsyncer_config = {
        rekeyFile = flake + /files/configs/vdirsyncer/config.age;
        path = "${config.home.homeDirectory}/.config/vdirsyncer/config";
        mode = "600";
      };

      # khal calendar CLI integration
      programs.khal = {
        enable = mkDefault true;
      };

      xdg.configFile."khal/config".source = "${khal_config}";
    }

    # Optional: Sync OAuth credentials via agenix-rekey
    (mkIf cfg.syncCredentials {
      age.secrets.vdirsyncer_google_token = {
        rekeyFile = flake + /files/configs/vdirsyncer/google_jadeisfalling_token.age;
        path = "${config.home.homeDirectory}/.local/state/vdirsyncer/google_jadeisfalling_token";
        mode = "600";
      };
    })
  ]);
}
