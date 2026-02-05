# ruinous.chat-organizer.enable = true;
#
# Automated chat log organization for Obsidian vaults.
# Uses local LLM (Ollama) to generate metadata and organize markdown files.
#
# Features:
# - Periodic scanning via systemd timer (Linux) or launchd (macOS)
# - Configurable directories to scan
# - Overlap prevention via flock
# - Recursive scanning with incremental updates
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.chat-organizer;

  # Build command flags based on options
  flags = lib.concatStringsSep " " (
    lib.optional cfg.recursive "-r"
    ++ lib.optional cfg.incremental "--incremental"
  );

  # Build the command arguments for each directory
  # Expands ~ to $HOME at runtime
  mkScanCommand = dir: ''
    # Expand ~ to actual home directory
    SCAN_DIR="${dir}"
    SCAN_DIR="''${SCAN_DIR/#\~/$HOME}"
    echo "Scanning directory: $SCAN_DIR"
    if [[ -d "$SCAN_DIR" ]]; then
      ${pkgs.chat-organizer}/bin/chat-organizer "$SCAN_DIR" ${flags}
    else
      echo "  [WARN] Directory does not exist: $SCAN_DIR"
    fi
  '';

  # Main sync script with flock to prevent overlapping runs
  syncScript = pkgs.writeShellScript "chat-organizer-sync" ''
    set -euo pipefail

    LOCK_FILE="/tmp/chat-organizer.lock"
    LOG_PREFIX="[chat-organizer]"

    # Use flock to prevent overlapping runs
    exec 200>"$LOCK_FILE"
    if ! ${pkgs.util-linux}/bin/flock -n 200; then
      echo "$LOG_PREFIX Another instance is already running. Skipping."
      exit 0
    fi

    echo "$LOG_PREFIX Starting sync at $(date)"

    # Check if Ollama is available
    if ! ${pkgs.curl}/bin/curl -sf "http://localhost:11434/api/tags" > /dev/null 2>&1; then
      echo "$LOG_PREFIX ERROR: Ollama is not running or not accessible"
      echo "$LOG_PREFIX Please ensure ollama is running: systemctl start ollama"
      exit 1
    fi

    # Scan each configured directory
    ${concatMapStringsSep "\n" mkScanCommand cfg.directories}

    echo "$LOG_PREFIX Sync completed at $(date)"
  '';
in {
  options.ruinous.chat-organizer = {
    enable = mkEnableOption "automated chat log organization for Obsidian";

    directories = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["~/Documents/Obsidian Vaults/Personal/Agent Chats"];
      description = ''
        List of directories to scan for chat logs.
        Paths can use ~ for home directory expansion.
      '';
    };

    interval = mkOption {
      type = types.str;
      default = "5m";
      example = "15m";
      description = ''
        How often to run the chat organizer.
        Uses systemd time format (e.g., "5m", "1h", "30s").
      '';
    };

    onBoot = mkOption {
      type = types.str;
      default = "2m";
      example = "5m";
      description = ''
        Delay before first run after boot.
        Uses systemd time format.
      '';
    };

    recursive = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Recursively scan subdirectories.
      '';
    };

    incremental = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Scan files WITH frontmatter and improve them
        (add missing fields, fix names).
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Linux: systemd timer for periodic sync
    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.chat-organizer = {
        Unit = {
          Description = "Chat log organizer for Obsidian";
          Documentation = "https://github.com/iamruinous/nix-config/tree/main/packages/chat-organizer";
          # Ollama should be available before we run
          After = ["network-online.target"];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${syncScript}";
          # Don't restart on failure - timer will retry
          Restart = "no";
          # Expand ~ in paths
          Environment = ["HOME=%h"];
        };
      };

      systemd.user.timers.chat-organizer = {
        Unit = {
          Description = "Periodic chat log organization";
        };
        Timer = {
          # Start after configured delay post-boot
          OnBootSec = cfg.onBoot;
          # Run at configured interval after last completion
          OnUnitInactiveSec = cfg.interval;
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
      launchd.agents.chat-organizer = {
        enable = true;
        config = {
          ProgramArguments = ["${syncScript}"];
          # Convert interval to seconds (default 5m = 300s)
          StartInterval = 300;
          # Run immediately on load
          RunAtLoad = true;
          # Log output
          StandardOutPath = "${config.home.homeDirectory}/.cache/chat-organizer/launchd-stdout.log";
          StandardErrorPath = "${config.home.homeDirectory}/.cache/chat-organizer/launchd-stderr.log";
        };
      };
    })

    # Core configuration (always enabled)
    {
      home.packages = [
        pkgs.chat-organizer
      ];

      # Ensure cache directory exists for logs
      home.activation.chatOrganizerDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.cache/chat-organizer"
      '';
    }
  ]);
}
