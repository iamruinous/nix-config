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
      enable = lib.mkEnableOption "Sync Claude Cowork sessions between machines";
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
          "claude-sessions" = {
            id = "claude-cowork-sessions";
            path = "~/Library/Application Support/Claude/local-agent-mode-sessions";
            devices = lib.attrNames cfg.devices;
            # Send & Receive (default)
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
