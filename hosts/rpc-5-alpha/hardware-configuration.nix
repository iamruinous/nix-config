{lib, ...}: {
  # Hardware configuration for Raspberry Pi 5
  # Most hardware config is handled by nixos-raspberrypi modules

  hardware.enableRedistributableFirmware = true;

  # File system configuration for SD card boot
  # NOTE: Update these labels after imaging if needed
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

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = "aarch64-linux";
}
