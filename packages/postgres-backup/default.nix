{pkgs, ...}:
pkgs.writeShellApplication {
  name = "postgres-backup";

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
    mainProgram = "postgres-backup";
    platforms = platforms.linux;
  };
}
