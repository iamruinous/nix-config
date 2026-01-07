{lib, ...}: {
  options = {
    ruinous.starship.battery.enable = lib.mkEnableOption "enable battery in starship";

    ruinous.openssh.tmux.attach.enable = lib.mkEnableOption "automatically start tmux on ssh";
    ruinous.openssh.remote.forwarding.enable = lib.mkEnableOption "forward agent on remote interactive shell";

    ruinous.tea.enable = lib.mkEnableOption "Whether to enable tea (Gitea CLI) with encrypted config";
  };
}
