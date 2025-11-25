# PostgreSQL Docker backup module
# Usage: ruinous.postgres.docker.backup.enable = true;
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.ruinous.postgres.docker.backup;
in {
  options.ruinous.postgres.docker.backup = {
    enable = lib.mkEnableOption "backup-docker-postgres";

    containerName = lib.mkOption {
      type = lib.types.str;
      default = "postgres";
      description = "Name of the Docker container running PostgreSQL";
      example = "my-postgres";
    };

    backupDir = lib.mkOption {
      type = lib.types.str;
      default = "/backup";
      description = "Directory path inside the container where backups will be stored";
      example = "/var/backups/postgres";
    };

    postgresUser = lib.mkOption {
      type = lib.types.str;
      default = "postgres";
      description = "PostgreSQL user to use for backup operations";
      example = "backup_user";
    };

    excludedDatabases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["template0" "template1" "postgres" "postgres=CTc/postgres"];
      description = "List of database names to exclude from backups";
      example = ["template0" "template1" "postgres" "test_db"];
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 01:00:00";
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
        EnvironmentFile = "/run/secrets/postgres-backup-env";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Create a customized version of the package with user's configuration
    environment.systemPackages = [
      (pkgs.backup-docker-postgres.override {
        containerName = cfg.containerName;
        backupDir = cfg.backupDir;
        postgresUser = cfg.postgresUser;
        excludedDatabases = cfg.excludedDatabases;
      })
    ];

    systemd.services.postgres-backup = {
      description = "PostgreSQL Docker backup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.backup-docker-postgres.override {
          containerName = cfg.containerName;
          backupDir = cfg.backupDir;
          postgresUser = cfg.postgresUser;
          excludedDatabases = cfg.excludedDatabases;
        }}/bin/backup-docker-postgres";
      } // cfg.serviceConfig;
    };

    systemd.timers.postgres-backup = {
      wantedBy = ["timers.target"];
      timerConfig = {
        Unit = "postgres-backup.service";
        OnCalendar = cfg.schedule;
        Persistent = cfg.persistent;
      };
    };
  };
}
