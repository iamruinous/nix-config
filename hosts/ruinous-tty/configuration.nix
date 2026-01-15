# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  flake,
  config,
  lib,
  ...
}: {
  imports = [
    flake.nixosModules.microvm
    flake.sharedModules.developer
  ];

  networking.hostName = "ruinous-tty";
  ruinous.kernel.useLatest = true;

  # Network configuration - static IP required for QEMU MicroVMs
  # systemd-networkd DHCP fails due to QEMU seccomp sandbox restrictions
  networking.useDHCP = false;
  networking.useNetworkd = false;
  networking.networkmanager.enable = lib.mkForce false;

  # Static IP configuration (DNS: ruinous.tty.meskill.farm)
  networking.interfaces.eth0 = {
    ipv4.addresses = [{
      address = "10.55.20.81";
      prefixLength = 24;
    }];
  };
  networking.defaultGateway = "10.55.20.1";
  networking.nameservers = ["1.1.1.1" "8.8.8.8"];

  # Disable services that don't work in microVM sandbox
  # QEMU's seccomp sandbox blocks syscalls these services need
  systemd.oomd.enable = false;
  services.resolved.enable = false;
  services.timesyncd.enable = false;
  # NSNCD fails under seccomp sandbox, breaking user lookups for SSH auth
  # Must also disable nssModules since they require nscd
  services.nscd.enable = false;
  system.nssModules = lib.mkForce [];

  nix.optimise.automatic = false;
  nix.settings.auto-optimise-store = false;

  fileSystems."/persistent".neededForBoot = true;

  microvm = {
    mem = 2047;
    vcpu = 2;
    hypervisor = "qemu";
    writableStoreOverlay = "/nix/.rw-store";

    interfaces = [
      {
        type = "macvtap";
        id = "mvtap2";
        macvtap.link = "enp2s0";
        macvtap.mode = "bridge";
        mac = "02:02:00:00:00:02";
      }
    ];

    volumes = [
      {
        image = "nix-store-overlay.img";
        mountPoint = config.microvm.writableStoreOverlay;
        size = 20480;
      }
    ];

    # It is highly recommended to share the host's nix-store
    # with the VMs to prevent building huge images.
    shares = [
      {
        source = "/persistent/microvms/ruinous-tty/persistent";
        mountPoint = "/persistent";
        tag = "persistent";
        proto = "virtiofs";
      }
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];
  };
  environment.persistence."/persistent" = {
    hideMounts = true; # Hide the mount point from the root
    users.jmeskill = {
      directories = [
        "Projects"
        ".gemini"
        ".local" # keep vim state
        ".cache"
        ".claude"
        ".go"
        ".npm"
        ".npm-devshells"
        ".config/gh"
        ".config/tea"
      ];
      files = [
        ".envrc"
        ".claude.json"
        ".ssh/known_hosts"
      ];
    };
    users.root = {
      directories = [
        ".ssh"  # Allow SSH access for debugging when home-manager fails
      ];
    };

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    # You can also persist system-wide directories or files here
    directories = [
      "/var/lib/nixos"
    ];
  };

  services.openssh.hostKeys = [
    {
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
