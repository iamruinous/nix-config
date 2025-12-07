{flake, ...}: {
  imports = [
    flake.homeModules.common
  ];
  home.stateVersion = "26.05";
}
