# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  flake,
  config,
  ...
}: {
  imports = [
    flake.inputs.microvm.nixosModules.microvm
    flake.inputs.impermanence.nixosModules.impermanence
    flake.nixosModules.default
    flake.nixosModules.developer
  ];

  networking.hostName = "ruinous-tty";

  nix.optimise.automatic = false;
  nix.settings.auto-optimise-store = false;

  fileSystems."/persistent".neededForBoot = true;

  microvm = {
    mem = 8191;
    vcpu = 16;
    hypervisor = "qemu";
    writableStoreOverlay = "/nix/.rw-store";

    interfaces = [
      {
        type = "macvtap";
        id = "mvtap2";
        macvtap.link = "vlan2";
        macvtap.mode = "vepa";
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
        ".npm"
        ".config/gh"
        ".config/tea"
      ];
      files = [
        ".claude.json"
        ".ssh/known_hosts"
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
