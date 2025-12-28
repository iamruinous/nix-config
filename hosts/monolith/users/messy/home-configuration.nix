{flake, ...}: {
  imports = [
    flake.homeModules.common
  ];

  ruinous.rust-motd.enable = true;

  home.stateVersion = "26.05";
}
