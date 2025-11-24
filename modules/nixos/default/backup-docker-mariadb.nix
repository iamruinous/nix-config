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
    systemd.services.mariadb-backup = {
      description = "mariadb backup";
      serviceConfig = {
        Type = "oneshot"; # For tasks that run and exit
        ExecStart = "${pkgs.mariadb-backup}/bin/mariadb-backup";
        # EnvironmentFile = add file with passwords (MARIADB_ROOT_PASSWORD)
      };
    };

    systemd.timers.mariadb-backup = {
      wantedBy = ["timers.target"]; # Ensures the timer starts with the system
      timerConfig = {
        Unit = "mariadb-backup.service"; # Links to the service defined above
        OnCalendar = "*-*-* 01:30:00"; # Example: run daily at midnight
        Persistent = true; # Ensures the timer runs even if the system was off during a scheduled run
      };
    };
  };
}
