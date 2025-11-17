{flake, ...}: {
  imports = [
    flake.darwinModules.default
    flake.nixosModules.developer
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "jmacmini";

  users.users.jmeskill.home = /Users/jmeskill;
  system.primaryUser = "jmeskill";

  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = 6;
}
