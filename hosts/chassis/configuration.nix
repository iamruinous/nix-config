# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{flake, ...}: {
  imports = [
    flake.inputs.disko.nixosModules.disko

    flake.sharedModules.developer
    flake.nixosModules.kde

    ./disko.nix
    ./hardware-configuration.nix
    ./caddy.nix
    ./postgres.nix
    ./budgey-dashboard.nix
    ./budgey-assistant.nix
    ./weaviate.nix
    ./ollama.nix
    ./harmonia.nix
  ];

  networking.hostName = "chassis";
  # Note: kernel handled by nixos-hardware framework-desktop module

  programs._1password.enable = true;
  programs.steam.enable = true;
  services.flatpak.enable = true;
  services.desktopManager.plasma6.enable = true;

  # enable dynamic libraries for tools like ruff
  programs.nix-ld.enable = true;

  # Enable power management (suspend/sleep support)
  powerManagement.enable = true;

  # KDE Remote Desktop (krfb) - VNC port for screen sharing
  networking.firewall.allowedTCPPorts = [5900];
  boot.plymouth.enable = true;
  users.mutableUsers = false;

  # hint about wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
