# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{flake, ...}: {
  imports = [
    flake.nixosModules.default
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "gap"; # Define your hostname.

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
