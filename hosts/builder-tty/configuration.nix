# builder-tty - Automation VM for docs package updates
#
# This MicroVM handles automated nix package updates triggered by
# Forgejo webhooks via n8n. It has git signing keys, SSH access to
# Forgejo, and gh CLI authentication for creating PRs.
#
# Triggered by: n8n workflow "Shared 2.0 - Update Docs Package"
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
  ];

  networking.hostName = "builder-tty";
  ruinous.kernel.useLatest = true;

  # Network configuration for microVM - use scripted networking instead of systemd-networkd
  # systemd-networkd has sandboxing issues in QEMU microvm environment
  networking.useDHCP = lib.mkForce true;
  networking.useNetworkd = false;
  networking.networkmanager.enable = false;
  networking.nameservers = ["1.1.1.1" "8.8.8.8"];

  # Disable services that don't work in microVM sandbox
  systemd.oomd.enable = false;
  services.resolved.enable = false;
  services.timesyncd.enable = false;

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
        macvtap.mode = "vepa";
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

  system.stateVersion = "25.05";
}
