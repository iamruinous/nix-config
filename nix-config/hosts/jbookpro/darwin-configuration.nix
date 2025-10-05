{flake, ...}: {
  imports = [
    flake.darwinModules.default
    flake.nixosModules.developer
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.jmeskill.home = /Users/jmeskill;
  system.primaryUser = "jmeskill";

  system.stateVersion = 6;
}
