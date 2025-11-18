{
  lib,
  osConfig,
  config,
  ...
}: {
  options = {
    ruinous.starship.battery.enable = lib.mkEnableOption "enable battery in starship";

    ruinous.openssh.tmux.attach.enable = lib.mkEnableOption "automatically start tmux on ssh";
    ruinous.openssh.remote.forwarding.enable = lib.mkEnableOption "forward agent on remote interactive shell";

    ruinous.todoist.sync.enable = lib.mkEnableOption "Whether to enable todoist auto-sync";

    ruinous.vdirsyncer.sync.enable = lib.mkEnableOption "Whether to enable vdirsyncer auto-sync";

    home.uid = lib.mkOption {
      type = with lib.types; nullOr int;
      default = osConfig.users.users.${config.home.username}.uid or null;
      description = ''
        Lookup uid from flake.users.<name>.uid and assign to config.home.uid
      '';
    };
  };
}
