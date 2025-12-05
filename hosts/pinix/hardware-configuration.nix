{
  lib,
  flake,
  ...
}: {
  imports = [
    # flake.inputs.nixos-raspberrypi.nixosModules.bootloader
    # flake.inputs.nixos-raspberrypi.nixosModules.nixpkgs-rpi
    flake.inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    flake.inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.display-vc4
    ./pi5-configtxt.nix
  ];

  fileSystems = {
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [
        "noatime"
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=1min"
      ];
    };

    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };
  };

  networking.useDHCP = lib.mkDefault true;
}
