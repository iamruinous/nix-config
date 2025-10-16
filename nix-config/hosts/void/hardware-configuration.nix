{lib, ...}: {
  networking.useDHCP = false;
  # networking.interfaces.enp4s0.useDHCP = lib.mkDefault true;

  # networking.firewall.enable = true;
  # networking.nftables.enable = true;
  systemd.network = {
    enable = true;
    networks = {
      "30-manage" = {
        matchConfig.Name = "enp4s0";
        networkConfig.DHCP = false;
        address = ["10.55.10.39/24"];
        gateway = ["10.55.10.1"];
        dns = ["10.55.10.35"];
      };
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-aarch64";
}
