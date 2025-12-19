{
  flake,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    flake.nixosModules.default
    flake.nixosModules.server

    ./hardware-configuration.nix
  ];

  networking.hostName = "rp500";

  # Use the recommended "kernel" bootloader for Raspberry Pi 5
  boot.loader.raspberryPi.bootloader = "kernel";

  # Resolve nixpkgs registry conflict between main nixpkgs and nixos-raspberrypi's nixpkgs
  # Force using the flake's nixpkgs for the registry
  nix.registry.nixpkgs.to = lib.mkForce {
    type = "path";
    path = inputs.nixpkgs.outPath;
  };

  # Disable UPS monitoring (no UPS connected to this Pi)
  power.ups.enable = lib.mkForce false;

  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # User configuration (since we're not using blueprint's auto-discovery)
  # The jmeskill user from users/jmeskill/default.nix
  users.users.jmeskill = {
    uid = 1000;
    isNormalUser = true;
    description = "Jade Meskill";
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm iamruinous@ruinous.social"
    ];
    shell = pkgs.fish;
  };

  # Allow wheel users to sudo without password for convenience during setup
  security.sudo.wheelNeedsPassword = false;

  # Allow mutable users during initial setup (override default module)
  users.mutableUsers = lib.mkForce true;

  # Override default shell (conflicts with bash.nix in nixos-raspberrypi)
  users.defaultUserShell = lib.mkForce pkgs.fish;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
