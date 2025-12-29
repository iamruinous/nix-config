# Common settings for Raspberry Pi hosts
{
  inputs,
  flake,
  lib,
  ...
}: {
  # include nixos.common by default
  imports = [
    flake.nixosModules.common
  ];
  # Use the recommended "kernel" bootloader for Raspberry Pi
  boot.loader.raspberryPi.bootloader = "kernel";

  # Resolve nixpkgs registry conflict between main nixpkgs and nixos-raspberrypi's nixpkgs
  # Force using the flake's nixpkgs for the registry
  nix.registry.nixpkgs.to = lib.mkForce {
    type = "path";
    path = inputs.nixpkgs.outPath;
  };

  # Allow mutable users during initial setup (Pis need this for first boot)
  users.mutableUsers = lib.mkForce true;
}
