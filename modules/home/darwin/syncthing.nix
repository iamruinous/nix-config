{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.ruinous.syncthing;
in {
  options.ruinous.syncthing = {
    enable = lib.mkEnableOption "Syncthing file synchronization";

    claudeSessions = {
      enable = lib.mkEnableOption ''
        Sync Claude Cowork sessions between machines.

        IMPORTANT LIMITATION: Claude Cowork uses Apple Virtualization.framework
        to run sessions in ephemeral Linux VMs. Each session references a
        VM sandbox name (e.g., "pensive-tender-faraday") that only exists
        on the originating machine.

        Syncing sessions allows you to:
        - View conversation history from other machines (read-only)
        - Access files created in session outputs/
        - Review todos, stats, and session metadata

        Syncing sessions does NOT allow you to:
        - Continue a session started on another machine
        - Resume VM state across machines

        Sessions synced from other machines will show an error when
        attempting to continue them. This is a Claude Desktop limitation,
        not a Syncthing issue.
      '';
    };

    devices = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          id = lib.mkOption {
            type = lib.types.str;
            description = "Syncthing device ID";
          };
        };
      });
      default = {};
      description = "Syncthing devices to sync with";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      package = pkgs.syncthing;

      # Don't override - allow manual additions via web UI initially
      overrideDevices = true;
      overrideFolders = true;

      settings = {
        # Devices configured per-host
        devices = lib.mapAttrs (name: device: {
          inherit (device) id;
          name = name;
          autoAcceptFolders = true;
        }) cfg.devices;

        # Folders
        folders = lib.mkIf cfg.claudeSessions.enable {
          # Sync Claude Cowork session data (read-only viewing, not continuation)
          # See module description for important limitations
          "claude-sessions" = {
            id = "claude-cowork-sessions";
            path = "~/Library/Application Support/Claude/local-agent-mode-sessions";
            devices = lib.attrNames cfg.devices;
            # Send & Receive - syncs session data for viewing
            # Note: Sessions cannot be continued on other machines due to VM sandbox architecture
            type = "sendreceive";
            # Keep versions for safety
            versioning = {
              type = "simple";
              params.keep = "5";
            };
          };
        };

        options = {
          # Accept anonymous usage reporting
          urAccepted = -1;
          # Enable local discovery for LAN sync
          localAnnounceEnabled = true;
          # Disable relays - only sync on local network / Tailscale
          relaysEnabled = false;
        };
      };
    };
  };
}
