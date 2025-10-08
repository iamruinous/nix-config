{flake, ...}: {
  imports = [
    flake.homeModules.default
  ];

  home.stateVersion = "25.05";
}
