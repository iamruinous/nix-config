{flake, ...}: {
  imports = [
    flake.darwinModules.common
    flake.sharedModules.developer
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "jbookpro";

  users.users.jmeskill.home = /Users/jmeskill;
  users.users.jmeskill.uid = 1000;
  system.primaryUser = "jmeskill";

  system.stateVersion = 6;
}
