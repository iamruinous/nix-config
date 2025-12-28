# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  flake,
  ...
}: {
  imports = [
    flake.nixosModules.default
    flake.nixosModules.developer
    flake.nixosModules.server
    ./hardware-configuration.nix
    ./containers.nix
    #./disko.nix
  ];

  networking.hostName = "tty-ruinous-social"; # Define your hostname.
  ruinous.kernel.useLatest = true;

  networking.usePredictableInterfaceNames = false;
  networking.firewall.enable = true;

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
  ];

  virtualisation.docker.enable = true;
  ruinous.postgres.docker.backup.enable = true;

  # update restic hostname to use tailscale
  # services.restic.backups.terranasbackup.repository = "sftp:tmbackup@terranas-1.greyhound-triceratops.ts.net:/mnt/tank/tmbackup/linux-backup/${config.networking.hostName}";
  ruinous.restic.terranas.enable = true;

  services.alloy.enable = true;
  ruinous.alloy.journal.enable = true;

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";

  #  services.openssh.settings.UsePAM = true;
  #  services.openssh.settings.AllowUsers = ["git"];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
