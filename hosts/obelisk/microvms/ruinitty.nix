{pkgs, ...}: let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm iamruinous@ruinous.social"
  ];
in {
  # The configuration for the MicroVM.
  # Multiple definitions will be merged as expected.
  system.stateVersion = "25.05";

  networking.hostName = "ruinitty";

  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  users.users.jmeskill = {
    password = "password";
    extraGroups = ["wheel"];
    group = "users";
    isNormalUser = true;
    openssh.authorizedKeys.keys = sshKeys;
  };

  microvm = {
    mem = 2047;
    vcpu = 2;
    hypervisor = "qemu";

    interfaces = [
      {
        type = "macvtap";
        id = "mvtap2";
        macvtap.link = "vlan2";
        macvtap.mode = "bridge";
        mac = "02:02:00:00:00:02";
      }
    ];

    # It is highly recommended to share the host's nix-store
    # with the VMs to prevent building huge images.
    shares = [
      {
        proto = "virtiofs";
        tag = "home";
        # Source path can be absolute or relative
        # to /var/lib/microvms/$hostName
        source = "home";
        mountPoint = "/home";
      }
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    gemini-cli
    git
    tmux
  ];

  # Fish configuration
  programs.fish.enable = true;
}
