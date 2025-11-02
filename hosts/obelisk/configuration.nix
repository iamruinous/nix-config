# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{flake, ...}: {
  imports = [
    flake.nixosModules.default
    flake.nixosModules.developer
    flake.nixosModules.hyprland

    ./hardware-configuration.nix
    ./containers.nix
    ./nfs.nix
    ./printing.nix
    ./microvm.nix
  ];

  networking.hostName = "obelisk"; # Define your hostname.

  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  services.printing.enable = true;

  ruinous.printing.discoverable = true;
  # programs.hyprland.enable = true;
  # programs._1password.enable = true;
  services.prometheus.exporters.node.enable = true;

  ruinous.restic.terranas.enable = true;
  services.alloy.enable = true;
  ruinous.alloy.journal.enable = true;
  x3ro.tailscale.enable = true;
  x3ro.tailscale.publicInterface = "vlan2";
  services.tailscale.extraUpFlags = ["--advertise-routes=10.55.0.0/16"];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
