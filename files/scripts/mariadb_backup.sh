#!/usr/bin/env bash

DB_USER="root"
DB_PASSWORD="${MARIADB_ROOT_PASSWORD}"
BACKUP_DIR="/backup"

# Get a list of databases (excluding system databases)
DATABASES=$(docker exec mariadb mysql -u"$DB_USER" -p"$DB_PASSWORD" -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

# Loop through each database and dump it
for DB_NAME in $DATABASES; do
    echo "Dumping database: '${DB_NAME}'"
    docker exec mariadb mariadb-dump -u"$DB_USER" -p"$DB_PASSWORD" --databases "$DB_NAME" > "$BACKUP_DIR/$DB_NAME.dump"
    if [ $? -eq 0 ]; then
        echo "Successfully dumped $DB_NAME to $BACKUP_DIR/$DB_NAME.sql"
    else
        echo "Error dumping $DB_NAME"
    fi
done

echo "Database dumping process complete."
