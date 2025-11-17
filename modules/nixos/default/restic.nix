# ruinous.restic.terranas.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.ruinous.restic.terranas;
in {
  config = lib.mkIf cfg.enable {
    # Enable restic backups
    services.restic.backups = {
      terranasbackup = {
        paths = [
          "/data"
          "/etc"
          "/home"
        ];
        exclude = [
          "/home/*/.cache"
          "/home/*/.cargo"
          "/home/*/.config"
          "/home/*/.local"
          "/home/*/.mozilla"
          "/home/*/.paradoxlauncher"
          "/home/*/.var"
          "/home/*/Downloads"
        ];
        initialize = lib.mkDefault true;
        repository = lib.mkDefault "sftp:${cfg.username}@${cfg.hostname}:/mnt/tank/tmbackup/linux-backup/${config.networking.hostName}";
        passwordFile = config.age.secrets.restic_password.path;
        timerConfig = {
          OnCalendar = "00:05";
          RandomizedDelaySec = "5h";
        };
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
          "--keep-yearly 75"
        ];
      };
    };

    age.secrets.restic_password = {
      rekeyFile = ../../../files/configs/restic/restic-password.age;
      mode = "600";
    };
  };
}
