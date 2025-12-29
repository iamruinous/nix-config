# Raspberry Pi 4 host configuration (RPC cluster member: echo)
# This file is auto-discovered by lib/pi.nix based on the pi4-configuration.nix filename
{flake, ...}: {
  imports = [
    flake.nixosModules.default
    flake.nixosModules.server
    flake.nixosModules.pi
    ./hardware-configuration.nix
  ];

  networking.hostName = "rpc-4-echo";

  system.stateVersion = "25.11";
}
