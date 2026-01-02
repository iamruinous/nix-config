# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  flake,
  ...
}: {
  imports = [
    flake.inputs.disko.nixosModules.disko

    flake.nixosModules.server
    flake.sharedModules.developer

    ./hardware-configuration.nix
    ./containers.nix
    ./disko.nix
    ./nfs.nix
    ./printing.nix
    ./caddy-cert-copy.nix
    ./cloudflared.nix
    ./sshd.nix
    ./rtl_433.nix
  ];

  networking.hostName = "monolith";
  ruinous.kernel.useLatest = true;

  programs.nix-ld.enable = true;

  systemd.services.mariadb-backup.serviceConfig.EnvironmentFile = config.age.secrets.monolith_docker_env_mariadb.path;
  ruinous.mariadb.docker.backup.enable = true;
  ruinous.postgres.docker.backup.enable = true;

  services.printing.enable = true;
  ruinous.printing.discoverable = true;
  virtualisation.docker.enable = true;
  ruinous.restic.terranas.enable = true;
  services.alloy.enable = true;
  ruinous.alloy.journal.enable = true;
  services.tailscale.enable = true;
  services.tailscale.extraUpFlags = ["--advertise-routes=10.55.0.0/16"];
  boot.plymouth.enable = true;
  power.ups.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
