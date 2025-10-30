{
  config,
  pkgs,
  lib,
  ...
}: let
  scripts_dir = ../../../files/scripts;
  mariadb_backup_script = "${scripts_dir}/mariadb_backup.sh";
  cfg = config.services.backup-docker-mariadb;
in {
  config = lib.mkIf cfg.enable {
    systemd.services.mariadb-backup = {
      description = "mariadb backup";
      path = with pkgs; [
        coreutils
        docker
      ];
      serviceConfig = {
        Type = "oneshot"; # For tasks that run and exit
        ExecStart = "${pkgs.bash}/bin/bash ${mariadb_backup_script}";
        # EnvironmentFile = add file with passwords
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
