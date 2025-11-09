# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{flake, ...}: let
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm iamruinous@ruinous.social"
  ];
in {
  imports = [
    flake.inputs.microvm.nixosModules.microvm
    flake.nixosModules.default
    flake.nixosModules.developer
  ];

  networking.hostName = "ruinous-tty";
  system.switch.enable = true;

  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  # users.users.jmeskill = {
  #   password = "password";
  #   extraGroups = ["wheel"];
  #   group = "users";
  #   isNormalUser = true;
  #   openssh.authorizedKeys.keys = sshKeys;
  # };

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
      # {
      #   proto = "virtiofs";
      #   tag = "home";
      #   # Source path can be absolute or relative
      #   # to /var/lib/microvms/$hostName
      #   source = "home";
      #   mountPoint = "/home";
      # }
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # services.openssh = {
  #   enable = true;
  # };

  # environment.systemPackages = with pkgs; [
  #   gemini-cli
  #   git
  #   tmux
  # ];

  # # Fish configuration
  # programs.fish.enable = true;
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
