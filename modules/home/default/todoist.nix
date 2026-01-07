# ruinous.todoist.enable = true;
#
# Manages todoist CLI with:
# - Encrypted config synced via agenix-rekey
# - Automatic sync via systemd timer (Linux) or launchd (macOS)
# - Robust sync script with error handling and logging
#
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.todoist;

  # Config and cache directories
  configDir = "${config.home.homeDirectory}/.config/todoist";
  cacheDir = "${config.home.homeDirectory}/.cache/todoist";

  # Robust sync script with error handling
  syncScript = pkgs.writeShellScript "todoist-sync" ''
    set -euo pipefail

    # Ensure directories exist
    mkdir -p "${configDir}"
    mkdir -p "${cacheDir}"

    # Check if config exists
    if [[ ! -f "${configDir}/config.json" ]]; then
      echo "Error: todoist config not found at ${configDir}/config.json" >&2
      echo "Ensure agenix secrets are properly decrypted" >&2
      exit 1
    fi

    # Run sync with timeout to prevent hanging
    echo "Starting todoist sync at $(date)"
    if timeout 60 ${pkgs.todoist}/bin/todoist sync; then
      echo "Sync completed successfully at $(date)"
    else
      exit_code=$?
      if [[ $exit_code -eq 124 ]]; then
        echo "Error: sync timed out after 60 seconds" >&2
      else
        echo "Error: sync failed with exit code $exit_code" >&2
      fi
      exit $exit_code
    fi
  '';
in {
  options.ruinous.todoist = {
    enable = mkEnableOption "todoist CLI with automatic sync";
  };

  config = mkIf cfg.enable (mkMerge [
    # Linux: systemd timer for periodic sync
    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.todoist-sync = {
        Unit = {
          Description = "todoist task sync";
          Documentation = "https://github.com/sachaos/todoist";
          # Don't fail if network is temporarily unavailable
          After = ["network-online.target"];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${syncScript}";
          # Retry on failure with exponential backoff
          Restart = "on-failure";
          RestartSec = "30s";
          # Limit retries to prevent spam
          RestartPreventExitStatus = "1";
        };
      };

      systemd.user.timers.todoist-sync = {
        Unit = {
          Description = "todoist periodic sync";
        };
        Timer = {
          # Start 1 minute after boot
          OnBootSec = "1m";
          # Then every 15 minutes after last run
          OnUnitInactiveSec = "15m";
          # Catch up if timer was missed (e.g., laptop was asleep)
          Persistent = true;
        };
        Install = {
          WantedBy = ["timers.target"];
        };
      };
    })

    # macOS: launchd agent for periodic sync
    (mkIf pkgs.stdenv.isDarwin {
      launchd.agents.todoist = {
        enable = true;
        config = {
          ProgramArguments = ["${syncScript}"];
          # Run every 15 minutes (900 seconds)
          StartInterval = 900;
          # Run immediately on load
          RunAtLoad = true;
          # Log output
          StandardOutPath = "${cacheDir}/launchd-stdout.log";
          StandardErrorPath = "${cacheDir}/launchd-stderr.log";
        };
      };
    })

    # Core configuration (always enabled)
    {
      home.packages = [
        pkgs.todoist
      ];

      # Encrypted todoist config (API token)
      age.secrets.todoist_config = {
        rekeyFile = flake + /files/configs/todoist/config.json.age;
        path = "${configDir}/config.json";
        mode = "600";
        symlink = false;
      };
    }
  ]);
}
