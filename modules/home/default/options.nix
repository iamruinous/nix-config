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

    ruinous.openssh.tmux.attach.enable = lib.mkEnableOption "automatically start tmux on ssh";
    ruinous.openssh.remote.forwarding.enable = lib.mkEnableOption "forward agent on remote interactive shell";

    ruinous.tea.enable = lib.mkEnableOption "Whether to enable tea (Gitea CLI) with encrypted config";

    ruinous.ssh.hosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule hostOpts);
      default = {};
      description = "Declarative SSH host definitions using 'user@hostname' format";
    };
  };
}
