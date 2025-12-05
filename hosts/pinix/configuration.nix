# from https://github.com/pdg137/pi5-nixos-setup
{
  config,
  flake,
  pkgs,
  lib,
  ...
}: {
  imports = [
    flake.nixosModules.default
    # flake.nixosModules.server
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # nixpkgs.overlays = [
  #   flake.inputs.nixos-raspberrypi.overlays.pkgs
  #   flake.inputs.nixos-raspberrypi.overlays.bootloader
  # ];

  networking.hostName = "pinix"; # Define your hostname.

  # boot = {
  #   tmp.useTmpfs = true;
  #   # loader.raspberryPi.firmwarePackage = kernelBundle.raspberrypifw;
  #   # kernelPackages = kernelBundle.linuxPackages_rpi5;
  # };

  # nixpkgs.overlays = lib.mkAfter [
  #   (self: super: {
  #     # This is used in (modulesPath + "/hardware/all-firmware.nix") when at least
  #     # enableRedistributableFirmware is enabled
  #     # I know no easier way to override this package
  #     inherit (kernelBundle) raspberrypiWirelessFirmware;
  #     # Some derivations want to use it as an input,
  #     # e.g. raspberrypi-dtbs, omxplayer, sd-image-* modules
  #     inherit (kernelBundle) raspberrypifw;
  #   })
  # ];

  # services.udev.extraRules = ''
  #   # Ignore partitions with "Required Partition" GPT partition attribute
  #   # On our RPis this is firmware (/boot/firmware) partition
  #   ENV{ID_PART_ENTRY_SCHEME}=="gpt", \
  #     ENV{ID_PART_ENTRY_FLAGS}=="0x1", \
  #     ENV{UDISKS_IGNORE}="1"
  # '';

  # system.nixos.tags = let
  #   cfg = config.boot.loader.raspberryPi;
  # in [
  #   "raspberry-pi-${cfg.variant}"
  #   cfg.bootloader
  #   config.boot.kernelPackages.kernel.version
  # ];

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
