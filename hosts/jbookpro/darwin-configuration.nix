{flake, ...}: {
  imports = [
    flake.darwinModules.default
    flake.nixosModules.developer
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "jbookpro";

  users.users.jmeskill.home = /Users/jmeskill;
  users.users.jmeskill.uid = 1000;
  system.primaryUser = "jmeskill";

  system.stateVersion = 6;
}
