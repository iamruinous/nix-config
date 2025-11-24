# ruinous.mariadb.docker.backup.enable = true;
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.ruinous.mariadb.docker.backup;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      backup-docker-mariadb
    ];

    systemd.services.mariadb-backup = {
      description = "mariadb backup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.backup-docker-mariadb}/bin/backup-docker-mariadb";
      };
    };

    systemd.timers.mariadb-backup = {
      wantedBy = ["timers.target"];
      timerConfig = {
        Unit = "mariadb-backup.service";
        OnCalendar = "*-*-* 01:30:00";
        Persistent = true;
      };
    };
  };
}
