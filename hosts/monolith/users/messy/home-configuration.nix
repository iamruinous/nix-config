{flake, ...}: {
  imports = [
    flake.homeModules.common
  ];
  home.stateVersion = "25.05";
}
