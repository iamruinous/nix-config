# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  flake,
  pkgs,
  ...
}: {
  imports = [
    flake.inputs.disko.nixosModules.disko

    flake.nixosModules.server
    flake.sharedModules.developer

    ./hardware-configuration.nix
    ./containers.nix
    ./disko.nix
  ];

  networking.hostName = "zenith";
  ruinous.kernel.useLatest = true;

  virtualisation.docker.enable = true;

  ruinous.postgres.docker.backup.enable = true;

  environment.systemPackages = with pkgs; [
    docker-mcp-gateway
  ];
  # services.alloy.enable = true;
  # ruinous.alloy.journal.enable = true;
  # power.ups.enable = true;
  services.tailscale.enable = true;
  services.tailscale.extraUpFlags = ["--advertise-routes=10.55.0.0/16"];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
