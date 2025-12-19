{lib, ...}: {
  # Hardware configuration for Raspberry Pi 500
  # Most hardware config is handled by nixos-raspberrypi modules

  hardware.enableRedistributableFirmware = true;

  # File system configuration for SD card / USB boot
  # NOTE: Update these UUIDs/labels after imaging the SD card
  # Use `lsblk -f` to find the actual UUIDs
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = ["noatime"];
  };

  swapDevices = [];

  # Networking
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = "aarch64-linux";
}
