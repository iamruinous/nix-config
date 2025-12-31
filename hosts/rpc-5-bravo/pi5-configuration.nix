# Raspberry Pi 5 host configuration (RPC cluster member: alpha)
# This file is auto-discovered by lib/pi.nix based on the pi5-configuration.nix filename
{flake, ...}: {
  imports = [
    flake.nixosModules.console
    flake.nixosModules.pi

    ./hardware-configuration.nix
  ];

  networking.hostName = "rpc-5-bravo";

  system.stateVersion = "25.11";
}
