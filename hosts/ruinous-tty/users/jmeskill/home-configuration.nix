{flake, ...}: {
  imports = [
    flake.homeModules.default
  ];

  ruinous.rust-motd.enable = true;
  ruinous.openssh.tmux.attach.enable = true;
  ruinous.tea.enable = true;

  home.stateVersion = "26.05";
}
