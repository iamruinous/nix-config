{flake, ...}: {
  imports = [
    flake.darwinModules.desktop
    flake.sharedModules.developer
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "jmacmini";

  users.users.jmeskill.home = /Users/jmeskill;
  users.users.jmeskill.uid = 1000;
  system.primaryUser = "jmeskill";

  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = 6;
}
