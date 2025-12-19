{lib, ...}: {
  # Hardware configuration for Raspberry Pi 500
  # Most hardware config is handled by nixos-raspberrypi modules

  hardware.enableRedistributableFirmware = true;

  # Networking
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = "aarch64-linux";
}
