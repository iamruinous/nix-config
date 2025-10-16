{...}: {
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

  swapDevices = [];
  networking.useDHCP = false;
  # networking.interfaces.enp4s0.useDHCP = lib.mkDefault true;

  # networking.firewall.enable = true;
  # networking.nftables.enable = true;
  systemd.network = {
    enable = true;
    networks = {
      "30-manage" = {
        matchConfig.Name = "enu1u1u1";
        networkConfig.DHCP = false;
        address = ["10.55.10.39/24"];
        gateway = ["10.55.10.1"];
        dns = ["10.55.10.35"];
      };
    };
  };

  nixpkgs.hostPlatform = "aarch64-linux";
}
