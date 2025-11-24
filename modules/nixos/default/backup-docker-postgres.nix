# ruinous.postgres.docker.backup.enable = true;
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.ruinous.postgres.docker.backup;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      backup-docker-postgres
    ];

    systemd.services.postgres-backup = {
      description = "postgres backup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.backup-docker-postgres}/bin/backup-docker-postgres";
      };
    };

    systemd.timers.postgres-backup = {
      wantedBy = ["timers.target"];
      timerConfig = {
        Unit = "postgres-backup.service";
        OnCalendar = "*-*-* 01:00:00";
        Persistent = true;
      };
    };
  };
}
