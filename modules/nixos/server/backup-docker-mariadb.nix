# MariaDB Docker backup module
# Usage: ruinous.mariadb.docker.backup.enable = true;
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.ruinous.mariadb.docker.backup;
in {
  options.ruinous.mariadb.docker.backup = {
    enable = lib.mkEnableOption "backup-docker-mariadb";

    containerName = lib.mkOption {
      type = lib.types.str;
      default = "mariadb";
      description = "Name of the Docker container running MariaDB";
      example = "my-mariadb";
    };

    backupDir = lib.mkOption {
      type = lib.types.str;
      default = "/backup";
      description = "Directory path on the host where backups will be stored";
      example = "/var/backups/mariadb";
    };

    mariadbUser = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "MariaDB user to use for backup operations";
      example = "backup_user";
    };

    excludedDatabases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["information_schema" "performance_schema" "mysql" "sys"];
      description = "List of database names to exclude from backups";
      example = ["information_schema" "performance_schema" "mysql" "sys" "test_db"];
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 01:30:00";
      description = "Systemd timer schedule (OnCalendar format)";
      example = "*-*-* 02:30:00";
    };

    persistent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to run missed backups if the system was off";
    };

    serviceConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional systemd service configuration options";
      example = {
        EnvironmentFile = "/run/secrets/mariadb-backup-env";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Create a customized version of the package with user's configuration
    environment.systemPackages = [
      (pkgs.backup-docker-mariadb.override {
        containerName = cfg.containerName;
        backupDir = cfg.backupDir;
        mariadbUser = cfg.mariadbUser;
        excludedDatabases = cfg.excludedDatabases;
      })
    ];

    systemd.services.mariadb-backup = {
      description = "MariaDB Docker backup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.backup-docker-mariadb.override {
          containerName = cfg.containerName;
          backupDir = cfg.backupDir;
          mariadbUser = cfg.mariadbUser;
          excludedDatabases = cfg.excludedDatabases;
        }}/bin/backup-docker-mariadb";
      } // cfg.serviceConfig;
    };

    systemd.timers.mariadb-backup = {
      wantedBy = ["timers.target"];
      timerConfig = {
        Unit = "mariadb-backup.service";
        OnCalendar = cfg.schedule;
        Persistent = cfg.persistent;
      };
    };
  };
}
