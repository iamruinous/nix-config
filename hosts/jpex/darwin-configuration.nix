{flake, ...}: {
  imports = [
    flake.darwinModules.desktop
    flake.darwinModules.tart-vm
    flake.sharedModules.developer
    ./tart.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "jpex";

  users.users.jmeskill.home = /Users/jmeskill;
  users.users.jmeskill.uid = 501;
  system.primaryUser = "jmeskill";

  homebrew.onActivation.cleanup = "none";

  system.stateVersion = 6;
}
