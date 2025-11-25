#!/usr/bin/env bash
# Backup MariaDB databases running in @docker@/bin/docker containers
# Automatically discovers and backs up all non-system databases

set -euo pipefail

# Configuration (will be substituted by Nix)
CONTAINER_NAME="@containerName@"
BACKUP_DIR="@backupDir@"
MARIADB_USER="@mariadbUser@"
EXCLUDED_DBS="@excludedDatabases@"

echo "Starting MariaDB backup for container: ${CONTAINER_NAME}"
echo "Backup directory: ${BACKUP_DIR}"

# Convert excluded databases string to array for easier checking
IFS=',' read -ra EXCLUDED_ARRAY <<< "$EXCLUDED_DBS"

# Function to check if database should be excluded
is_excluded() {
  local db_name="$1"

  for excluded in "${EXCLUDED_ARRAY[@]}"; do
    # Trim whitespace
    excluded="$(echo "$excluded" | xargs)"
    if [[ "$db_name" == "$excluded" ]]; then
      return 0
    fi
  done
  return 1
}

# Get list of databases and dump each one
@docker@/bin/docker exec "$CONTAINER_NAME" mysql -u"$MARIADB_USER" -p"${MARIADB_ROOT_PASSWORD}" -e "SHOW DATABASES;" | \
  tail -n +2 | \
  while read -r DB_NAME; do
    # Skip empty names
    if [[ -z "$DB_NAME" ]]; then
      continue
    fi

    # Skip excluded databases
    if is_excluded "$DB_NAME"; then
      echo "Skipping excluded database: ${DB_NAME}"
      continue
    fi

    echo "Dumping database: ${DB_NAME}"
    if @docker@/bin/docker exec "$CONTAINER_NAME" mariadb-dump \
      -u"$MARIADB_USER" \
      -p"${MARIADB_ROOT_PASSWORD}" \
      --databases "$DB_NAME" \
      > "${BACKUP_DIR}/${DB_NAME}.dump"; then
      echo "Successfully dumped ${DB_NAME} to ${BACKUP_DIR}/${DB_NAME}.dump"
    else
      echo "Error dumping ${DB_NAME}" >&2
    fi
  done

echo "MariaDB backup process complete."
