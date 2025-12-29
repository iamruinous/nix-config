# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  lib,
  inputs,
  flake,
  ...
}: {
  imports = [
    flake.nixosModules.default
    flake.sharedModules.developer
    flake.nixosModules.desktop
    flake.desktopModules.kde
    flake.inputs.lanzaboote.nixosModules.lanzaboote
    inputs.hardware.nixosModules.framework-intel-core-ultra-series1

    ./hardware-configuration.nix
  ];

  networking.hostName = "framework"; # Define your hostname.
  ruinous.kernel.useLatest = true;

  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    #    settings.reboot-for-bitlocker = true;
  };

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/efi";
  boot.loader.systemd-boot.xbootldrMountPoint = "/boot";

  environment.systemPackages = with pkgs; [
    dwarf-fortress
  ];

  services.printing.enable = true;
  ruinous.printing.discoverable = true;
  programs._1password.enable = true;
  programs.steam.enable = true;
  services.flatpak.enable = true;
  services.desktopManager.plasma6.enable = true;
  boot.plymouth.enable = true;

  # hint about wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Enable the Hyprland DM
  # programs.hyprland = {
  #   enable = true;
  #   xwayland.enable = true;
  # };

  # Enable the UWSM
  # programs.uwsm = {
  #   enable = true;
  #   waylandCompositors = "hyprland";
  # };

  services.xserver.updateDbusEnvironment = true;
  # Enable security services
  security.polkit.enable = true;
  # security.pam.services = {
  #   hyprlock = {};
  # };

  # Enable login with fingerprint reader
  security.pam.services.login.fprintAuth = true;

  # this system has a battery
  programs.starship.settings.battery.disabled = false;

  # Enable power management (suspend/sleep support)
  powerManagement.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
