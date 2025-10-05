# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  flake,
  ...
}: {
  imports = [
    flake.nixosModules.default
    flake.nixosModules.developer
    flake.nixosModules.bork
    ./hardware-configuration.nix
    ./containers.nix
    #./disko.nix
  ];

  networking.hostName = "tty-ruinous-social"; # Define your hostname.
  networking.usePredictableInterfaceNames = false;
  networking.firewall.enable = true;
  networking.firewall.interfaces."eth0".allowedTCPPorts = [80 443];
  networking.firewall.interfaces."eth0".allowedUDPPorts = [443];

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
  ];

  virtualisation.arion.enable = true;

  # update restic hostname to use tailscale
  services.restic.backups.terranasbackup.repository = "sftp:tmbackup@terranas-1.greyhound-triceratops.ts.net:/mnt/tank/tmbackup/linux-backup/${config.networking.hostName}";
  services.restic.terranas = true;

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
