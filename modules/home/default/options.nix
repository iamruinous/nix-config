{lib, ...}: let
  # Host definition type for ruinous.ssh.hosts
  hostOpts = {name, ...}: {
    options = {
      host = lib.mkOption {
        type = lib.types.str;
        description = "SSH connection string in format 'user@hostname'";
      };
      aliases = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional SSH config aliases for this host";
      };
      extraOptions = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Extra SSH options for this host";
      };
      forwardAgent = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Enable/disable agent forwarding";
      };
      addKeysToAgent = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "AddKeysToAgent setting";
      };
    };
  };
in {
  options = {
    ruinous.starship.battery.enable = lib.mkEnableOption "enable battery in starship";

    # DEPRECATED: Use ruinous.loginHub.enable instead.
    # This option is kept for backward compatibility during migration.
    # Migration path: Replace with ruinous.loginHub.enable = true;
    ruinous.openssh.tmux.attach.enable = lib.mkEnableOption "automatically start tmux on ssh";
    ruinous.openssh.remote.forwarding.enable = lib.mkEnableOption "forward agent on remote interactive shell";

    ruinous.tea.enable = lib.mkEnableOption "Whether to enable tea (Gitea CLI) with encrypted config";

    # SSH login hub options
    ruinous.loginHub = {
      enable = lib.mkEnableOption "SSH login hub with TUI menu";

      bypassEnvVar = lib.mkOption {
        type = lib.types.str;
        default = "BYPASS_LOGIN_HUB";
        description = "Environment variable to bypass the login hub";
      };

      hubSessionName = lib.mkOption {
        type = lib.types.str;
        default = "hub";
        description = "Name of the hub tmux session";
      };

      showTmuxpSessions = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Auto-discover and show tmuxp sessions in menu";
      };
    };

    ruinous.ssh.hosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule hostOpts);
      default = {};
      description = "Declarative SSH host definitions using 'user@hostname' format";
    };
  };
}
