{flake, ...}: {
  imports = [
    flake.homeModules.default
  ];

  ruinous.rust-motd.enable = true;

  home.stateVersion = "26.05";
}
