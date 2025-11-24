# backup-docker-postgres

A NixOS package and module for backing up PostgreSQL databases running in Docker containers.

## Overview

This package provides a shell script that automatically backs up all PostgreSQL databases (except system databases) from a Docker container to a specified backup directory. The backups are created in PostgreSQL's custom compressed format.

## Features

- Automatic discovery of all databases in the PostgreSQL container
- Skips system databases (template0, template1, postgres)
- Creates compressed backups using `pg_dump` custom format (`-Fc -Z 9`)
- Includes integrated NixOS module with systemd service and timer
- Runs daily at 01:00 by default

## Usage

### As a Standalone Package

Build and run the backup script directly:

```bash
# Build the package
nix build .#backup-docker-postgres

# Run the backup
./result/bin/backup-docker-postgres
```

### As a NixOS Module

Enable the backup service in your NixOS configuration:

```nix
{
  # Enable PostgreSQL Docker backup
  ruinous.postgres.docker.backup.enable = true;
}
```

This will automatically:
- Install the backup script
- Create a systemd service (`postgres-backup.service`)
- Create a systemd timer that runs daily at 01:00
- Persist the timer across reboots

## Requirements

- Docker container named `postgres` must be running
- PostgreSQL container must have a `postgres` superuser
- Backup directory `/backup` must exist and be writable from within the container

## Backup Location

Backups are written to `/backup` inside the PostgreSQL container:
- Format: `/backup/<database_name>.dump`
- Compression: Custom format with level 9 compression
- Naming: Each database gets its own `.dump` file

## Customization

The systemd service runs as a oneshot service with the following default schedule:
- **Schedule**: Daily at 01:00 (1 AM)
- **Persistent**: Yes (runs missed backups if system was off)

To customize the schedule, override the timer configuration in your NixOS config:

```nix
{
  systemd.timers.postgres-backup.timerConfig.OnCalendar = "*-*-* 02:00:00";  # 2 AM
}
```

## Technical Details

### Database Exclusions

The following databases are excluded from backups:
- `template0` - PostgreSQL template database
- `template1` - PostgreSQL template database
- `postgres` - PostgreSQL default database
- `postgres=CTc/postgres` - System metadata entry

### Backup Command

Each database is backed up using:
```bash
docker exec postgres pg_dump \
  -Fc \
  -Z 9 \
  --user="postgres" \
  --no-owner \
  --no-privileges \
  --dbname="$DB_NAME" \
  --file="/backup/$DB_NAME.dump"
```

Flags:
- `-Fc`: Custom format (compressed and restorable with pg_restore)
- `-Z 9`: Maximum compression level
- `--no-owner`: Don't output ownership commands
- `--no-privileges`: Don't output privilege commands

## Monitoring

Check the status of the backup service:

```bash
# View service status
systemctl status postgres-backup.service

# View timer status
systemctl status postgres-backup.timer

# View recent logs
journalctl -u postgres-backup.service -n 50
```

## Restoring from Backup

To restore a database from a backup:

```bash
# Copy backup file to container (if needed)
docker cp /backup/mydb.dump postgres:/tmp/

# Restore the database
docker exec postgres pg_restore \
  -U postgres \
  -d mydb \
  /tmp/mydb.dump
```

## See Also

- [backup-docker-mariadb](../backup-docker-mariadb/) - Similar backup solution for MariaDB
- [NixOS systemd services](https://nixos.org/manual/nixos/stable/#sect-systemd-services)
