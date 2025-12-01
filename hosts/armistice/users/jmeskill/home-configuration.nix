{flake, ...}: {
  imports = [
    flake.homeModules.default
  ];

  ruinous.openssh.tmux.attach.enable = true;

  home.stateVersion = "25.05";
}
