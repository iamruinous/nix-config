{
  lib,
  flake,
  ...
}: {
  imports = [
    flake.homeModules.common
  ];

  options = {
    ruinous.starship.battery.enable = lib.mkEnableOption "enable battery in starship";

    ruinous.openssh.tmux.attach.enable = lib.mkEnableOption "automatically start tmux on ssh";
    ruinous.openssh.remote.forwarding.enable = lib.mkEnableOption "forward agent on remote interactive shell";

    ruinous.todoist.sync.enable = lib.mkEnableOption "Whether to enable todoist auto-sync";

    ruinous.vdirsyncer.sync.enable = lib.mkEnableOption "Whether to enable vdirsyncer auto-sync";
  };
}
