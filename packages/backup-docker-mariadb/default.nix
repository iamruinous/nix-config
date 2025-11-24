{pkgs, ...}: let
  script = pkgs.writeShellApplication {
    name = "backup-docker-mariadb";

    runtimeInputs = with pkgs; [
      docker
      coreutils
    ];

    text = ''
      DB_USER="root"
      DB_PASSWORD="''${MARIADB_ROOT_PASSWORD}"
      BACKUP_DIR="/backup"

      # Get a list of databases (excluding system databases)
      DATABASES=$(docker exec mariadb mysql -u"$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

      # Loop through each database and dump it
      for DB_NAME in $DATABASES; do
          echo "Dumping database: ''\${DB_NAME}"
          if docker exec mariadb mariadb-dump -u"$DB_USER" -p"$DB_PASSWORD" --databases "$DB_NAME" > "$BACKUP_DIR/$DB_NAME.dump"; then
              echo "Successfully dumped $DB_NAME to $BACKUP_DIR/$DB_NAME.sql"
          else
              echo "Error dumping $DB_NAME"
          fi
      done

      echo "Database dumping process complete."
    '';

    meta = with pkgs.lib; {
      description = "Backup script for MariaDB databases running in Docker containers";
      mainProgram = "backup-docker-mariadb";
      platforms = platforms.linux;
    };
  };
in
  script
  // {
    passthru.nixosModules.default = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.ruinous.mariadb.docker.backup;
    in {
      options = {
        ruinous.mariadb.docker.backup.enable = lib.mkEnableOption "backup-docker-mariadb";
      };

      config = lib.mkIf cfg.enable {
        systemd.services.mariadb-backup = {
          description = "mariadb backup";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.backup-docker-mariadb}/bin/backup-docker-mariadb";
            # EnvironmentFile can be set to provide MARIADB_ROOT_PASSWORD
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
    };
  }
