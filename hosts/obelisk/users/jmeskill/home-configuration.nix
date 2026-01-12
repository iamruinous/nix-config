{flake, ...}: {
  imports = [
    flake.homeModules.default
  ];

  ruinous.rust-motd.enable = true;
  ruinous.loginHub.enable = true;

  home.stateVersion = "26.05";
}
