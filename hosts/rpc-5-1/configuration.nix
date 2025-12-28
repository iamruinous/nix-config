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

  networking.hostName = "rpc-5-1";

  # Use the recommended "kernel" bootloader for Raspberry Pi 5
  boot.loader.raspberryPi.bootloader = "kernel";

  # Resolve nixpkgs registry conflict between main nixpkgs and nixos-raspberrypi's nixpkgs
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

  # User configuration
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

  security.sudo.wheelNeedsPassword = false;
  users.mutableUsers = lib.mkForce true;
  users.defaultUserShell = lib.mkForce pkgs.fish;

  system.stateVersion = "25.11";
}
