# Common settings for Raspberry Pi hosts
{
  inputs,
  lib,
  ...
}: {
  # Enable dynamic login prompt with system info
  ruinous.dynamicIssue.enable = true;
  # Use the recommended "kernel" bootloader for Raspberry Pi
  boot.loader.raspberryPi.bootloader = "kernel";

  # Resolve nixpkgs registry conflict between main nixpkgs and nixos-raspberrypi's nixpkgs
  # Force using the flake's nixpkgs for the registry
  nix.registry.nixpkgs.to = lib.mkForce {
    type = "path";
    path = inputs.nixpkgs.outPath;
  };

  # Disable UPS monitoring (no UPS connected to Pis)
  power.ups.enable = lib.mkForce false;

  # Allow mutable users during initial setup (Pis need this for first boot)
  users.mutableUsers = lib.mkForce true;
}
