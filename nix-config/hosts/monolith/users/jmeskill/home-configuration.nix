{flake, ...}: {
  imports = [
    flake.homeModules.default
  ];

  programs.ssh-interactive.enable = true;

  home.stateVersion = "25.05";
}
