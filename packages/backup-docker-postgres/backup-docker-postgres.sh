#!/usr/bin/env bash
# Backup PostgreSQL databases running in Docker containers
# Automatically discovers and backs up all non-system databases

set -euo pipefail

# Configuration (will be substituted by Nix)
CONTAINER_NAME="@containerName@"
BACKUP_DIR="@backupDir@"
POSTGRES_USER="@postgresUser@"
EXCLUDED_DBS="@excludedDatabases@"

echo "Starting PostgreSQL backup for container: ${CONTAINER_NAME}"
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

# Dump individual databases directly to backup directory
docker exec "$CONTAINER_NAME" psql -U "$POSTGRES_USER" -q -l -t -A --pset=pager=off | \
  awk -F'|' '{print $1}' | \
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
    if docker exec "$CONTAINER_NAME" pg_dump \
      -Fc \
      -Z 9 \
      --user="$POSTGRES_USER" \
      --no-owner \
      --no-privileges \
      --dbname="$DB_NAME" \
      --file="${BACKUP_DIR}/${DB_NAME}.dump"; then
      echo "Successfully dumped ${DB_NAME} to ${BACKUP_DIR}/${DB_NAME}.dump"
    else
      echo "Error dumping ${DB_NAME}" >&2
    fi
  done

echo "PostgreSQL backup process complete."
