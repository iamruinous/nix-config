{pkgs, ...}: let
  script = pkgs.writeShellApplication {
    name = "backup-docker-postgres";

    runtimeInputs = with pkgs; [
      docker
      gawk
      coreutils
    ];

    text = ''
      BACKUP_DIR="/backup"

      # Dump individual databases directly to restic repository.
      docker exec postgres psql -U postgres -q -l -t -A --pset=pager=off | awk -F'|' '{print $1}' | while read -r DB_NAME; do
        if [[ -n "$DB_NAME" && "$DB_NAME" != "template0" && "$DB_NAME" != "template1" && "$DB_NAME" != "postgres" && "$DB_NAME" != "postgres=CTc/postgres" ]]; then
          echo "Dumping database: ''\${DB_NAME}"
          if docker exec postgres pg_dump -Fc -Z 9 --user="postgres" --no-owner --no-privileges --dbname="$DB_NAME" --file="''${BACKUP_DIR}/''${DB_NAME}.dump"; then
              echo "Successfully dumped $DB_NAME to $BACKUP_DIR/$DB_NAME.sql"
          else
              echo "Error dumping $DB_NAME"
          fi
        fi
      done
    '';

    meta = with pkgs.lib; {
      description = "Backup script for PostgreSQL databases running in Docker containers";
      mainProgram = "backup-docker-postgres";
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
      cfg = config.ruinous.postgres.docker.backup;
    in {
      options = {
        ruinous.postgres.docker.backup.enable = lib.mkEnableOption "backup-docker-postgres";
      };

      config = lib.mkIf cfg.enable {
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
    };
  }
