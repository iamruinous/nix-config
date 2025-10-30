{flake, ...}: {
  imports = [
    # ../modules/common.nix
    # ../modules/developer.nix
    flake.darwinModules.default
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.jmeskill.home = /Users/jmeskill;
  system.primaryUser = "jmeskill";

  system.stateVersion = 6; # initial nix-darwin state
}
