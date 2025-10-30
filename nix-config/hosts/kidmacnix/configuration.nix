# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  flake,
  ...
}: {
  imports = [
    flake.nixosModules.default
    flake.nixosModules.developer
    flake.nixosModules.desktop
    flake.inputs.disko.nixosModules.disko
    inputs.hardware.nixosModules.apple-imac-18-2
    ./hardware-configuration.nix
    ./disko.nix
    # ../modules/common.nix
    # ../modules/developer.nix
    # ../modules/nixos/desktop-common.nix
    # ../modules/nixos/flatpak.nix
    # ../modules/nixos/kde.nix
    # ../modules/nixos/latest-kernel.nix
  ];

  services.desktopManager.plasma6.enable = true;

  hardware.facetimehd.enable = false;

  networking.hostName = "kidmacnix"; # Define your hostname.

  # autologin
  services.displayManager = {
    autoLogin.enable = true;
    autoLogin.user = "jmeskill"; # TODO: generalize user
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
