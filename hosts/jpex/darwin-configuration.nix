{flake, ...}: {
  imports = [
    flake.darwinModules.desktop
    flake.sharedModules.developer
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "jpex";

  users.users.jmeskill.home = /Users/jmeskill;
  users.users.jmeskill.uid = 501;
  system.primaryUser = "jmeskill";

  homebrew.onActivation.cleanup = "none";

  system.stateVersion = 6;
}
