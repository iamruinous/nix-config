{flake, ...}: {
  imports = [
    flake.homeModules.default
  ];

  ruinous.rust-motd.enable = true;
}
