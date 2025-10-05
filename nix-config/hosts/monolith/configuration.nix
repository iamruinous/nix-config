# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  flake,
  ...
}: {
  imports = [
    flake.nixosModules.default
    flake.nixosModules.developer
    flake.nixosModules.bork
    flake.inputs.disko.nixosModules.disko

    ./hardware-configuration.nix
    # ../modules/nixos/backup-docker-mariadb.nix
    # ../modules/nixos/backup-docker-postgres.nix
    ./containers.nix
    ./disko.nix
    ./nfs.nix
    ./printing.nix
    ./rtl_433.nix
  ];

  networking.hostName = "monolith"; # Define your hostname.

  services.tailscale.useRoutingFeatures = "server";

  programs.nix-ld.enable = true;

  systemd.services.mariadb-backup.serviceConfig.EnvironmentFile = config.age.secrets.monolith_docker_env_mariadb.path;

  services.printing.enable = true;
  services.printing.discoverable = true;
  virtualisation.arion.enable = true;
  services.restic.terranas = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
