{flake, ...}: {
  imports = [
    flake.darwinModules.default
    flake.nixosModules.developer
  ];

  nixpkgs.hostPlatform = "x86_64-darwin";

  networking.hostName = "studio";

  users.users.jmeskill.home = /Users/jmeskill;
  users.users.jmeskill.uid = 1000;
  system.primaryUser = "jmeskill";

  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = 6;
}
