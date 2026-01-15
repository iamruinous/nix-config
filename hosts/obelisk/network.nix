# Network configuration for obelisk with macvlan for MicroVM communication
#
# macvtap interfaces (used by MicroVMs) have a known limitation where the host
# cannot communicate with VMs when they share the same physical interface.
# The solution is to create a macvlan interface for the host, making it an
# equal peer on the macvlan bridge.
#
# Network topology:
#   enp2s0 (physical) - no IP, just carrier
#     ├── mv-host (macvlan, bridge mode) - host's IP via DHCP
#     ├── mvtap-builder (macvtap) - builder-tty VM
#     ├── mvtap1 (macvtap) - messy-tty VM
#     └── mvtap2 (macvtap) - ruinous-tty VM
#
# This allows host <-> VM communication on the same L2 segment.
#
# Reference: https://wiki.libvirt.org/TroubleshootMacvtapHostFail.html
{lib, ...}: {
  # Ensure macvlan kernel module is loaded
  boot.kernelModules = ["macvlan"];

  networking.useDHCP = lib.mkDefault false;
  networking.wireless.enable = lib.mkDefault false;
  networking.networkmanager.enable = false;
  networking.firewall.enable = true;
  networking.nftables.enable = true;

  systemd.network.enable = true;

  # Create macvlan netdev for host communication
  systemd.network.netdevs."20-mv-host" = {
    netdevConfig = {
      Name = "mv-host";
      Kind = "macvlan";
    };
    extraConfig = ''
      [MACVLAN]
      Mode=bridge
    '';
  };

  # Physical interface - no IP, just carrier, with macvlan attached
  systemd.network.networks."10-enp2s0" = {
    matchConfig.Name = "enp2s0";
    # This interface should only be used from attached macvlans.
    # Don't acquire a link local address and only wait for carrier.
    networkConfig = {
      LinkLocalAddressing = "no";
      MACVLAN = ["mv-host"];
    };
    linkConfig = {
      RequiredForOnline = "carrier";
    };
  };

  # Macvlan interface - host's actual network connection
  systemd.network.networks."20-mv-host" = {
    matchConfig.Name = "mv-host";
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = true;
    };
    linkConfig = {
      RequiredForOnline = "routable";
    };
  };

  # Ignore macvtap interfaces created by MicroVMs - let QEMU manage them
  systemd.network.networks."90-macvtap-ignore" = {
    matchConfig.Kind = "macvtap";
    linkConfig = {
      ActivationPolicy = "manual";
      Unmanaged = "yes";
    };
  };
}
