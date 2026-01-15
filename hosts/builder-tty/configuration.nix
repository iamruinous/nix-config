# builder-tty - Automation VM for docs package updates
#
# This MicroVM handles automated nix package updates triggered by
# Forgejo webhooks via n8n. It has git signing keys, SSH access to
# Forgejo, and gh CLI authentication for creating PRs.
#
# Triggered by: n8n workflow via builder-bot-mcp FastMCP server
# Purpose: Receive tag notifications, compute hashes, create PRs
{
  flake,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    flake.nixosModules.microvm
    flake.sharedModules.developer
    flake.inputs.builder-bot-mcp.nixosModules.default
  ];

  networking.hostName = "builder-tty";
  ruinous.kernel.useLatest = true;

  # Network configuration - static IP required for QEMU MicroVMs
  # systemd-networkd DHCP fails due to QEMU seccomp sandbox restrictions
  networking.useDHCP = false;
  networking.useNetworkd = false;
  networking.networkmanager.enable = lib.mkForce false;

  # Static IP configuration (DNS: builder.tty.meskill.farm)
  networking.interfaces.eth0 = {
    ipv4.addresses = [{
      address = "10.55.20.82";
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

  # Disable store optimization (shared store with host)
  nix.optimise.automatic = false;
  nix.settings.auto-optimise-store = false;

  fileSystems."/persistent".neededForBoot = true;

  microvm = {
    mem = 4096; # 4GB for nix builds
    vcpu = 4; # 4 cores for parallel operations
    hypervisor = "qemu";
    writableStoreOverlay = "/nix/.rw-store";

    interfaces = [
      {
        type = "macvtap";
        id = "mvtap-builder";
        macvtap.link = "enp2s0";
        macvtap.mode = "bridge";
        mac = "02:02:00:00:00:10"; # Unique MAC for builder-tty
      }
    ];

    volumes = [
      {
        image = "nix-store-overlay.img";
        mountPoint = config.microvm.writableStoreOverlay;
        size = 20480; # 20GB for builds
      }
    ];

    shares = [
      {
        proto = "virtiofs";
        tag = "persistent";
        source = "/persistent/microvms/builder-tty/persistent";
        mountPoint = "/persistent";
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
    hideMounts = true;
    users.builder = {
      directories = [
        "Projects"
        ".gnupg"
        ".ssh"
        ".cache"
        "bin"
        ".config/gh" # gh CLI auth state
      ];
      files = [
        ".gitconfig"
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

    directories = [
      "/var/lib/nixos"
    ];
  };

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # Additional packages for automation scripts
  environment.systemPackages = with pkgs; [
    # Nix tooling
    nix-prefetch-git

    # Script utilities
    gnused
    coreutils
  ];

  # builder-bot-mcp FastMCP server for n8n automation
  services.builder-bot-mcp = {
    enable = true;
    port = 8000;
    host = "0.0.0.0";
    configFile = config.age.secrets.builder_bot_config.path;
    user = "builder";
    group = "users";
    workingDirectory = "/home/builder/Projects/nix-config";
  };

  # Agenix secret for builder-bot-mcp configuration
  age.secrets.builder_bot_config = {
    rekeyFile = ./files/builder-bot-mcp/repos.json.age;
    owner = "builder";
    group = "users";
    mode = "0400";
  };

  system.stateVersion = "25.05";
}
