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

The package can be customized with override:

```nix
pkgs.backup-docker-postgres.override {
  containerName = "my-postgres";
  backupDir = "/var/backups";
  postgresUser = "backup_user";
  excludedDatabases = ["template0" "template1" "test_db"];
}
```

### As a NixOS Module

Enable the backup service in your NixOS configuration:

```nix
{
  # Enable PostgreSQL Docker backup with defaults
  ruinous.postgres.docker.backup.enable = true;
}
```

This will automatically:
- Install the backup script
- Create a systemd service (`postgres-backup.service`)
- Create a systemd timer that runs daily at 01:00
- Persist the timer across reboots

## Module Options

The NixOS module provides comprehensive configuration options:

```nix
{
  ruinous.postgres.docker.backup = {
    enable = true;                # Enable the backup service

    containerName = "postgres";   # Docker container name
    backupDir = "/backup";        # Backup directory inside container
    postgresUser = "postgres";    # PostgreSQL user for backups

    excludedDatabases = [         # Databases to skip
      "template0"
      "template1"
      "postgres"
      "postgres=CTc/postgres"
    ];

    schedule = "*-*-* 01:00:00";  # Systemd timer schedule (OnCalendar format)
    persistent = true;            # Run missed backups if system was off

    serviceConfig = {};           # Additional systemd service options
  };
}
```

### Configuration Examples

**Custom schedule (backup at 2:30 AM):**
```nix
{
  ruinous.postgres.docker.backup = {
    enable = true;
    schedule = "*-*-* 02:30:00";
  };
}
```

**Different container and backup location:**
```nix
{
  ruinous.postgres.docker.backup = {
    enable = true;
    containerName = "my-postgres";
    backupDir = "/var/backups/postgres";
  };
}
```

**With environment file for secrets:**
```nix
{
  ruinous.postgres.docker.backup = {
    enable = true;
    serviceConfig = {
      EnvironmentFile = "/run/secrets/postgres-backup-env";
    };
  };
}
```

## Requirements

- Docker container must be running (default name: `postgres`)
- PostgreSQL container must have the specified user (default: `postgres`)
- Backup directory must exist and be writable from within the container (default: `/backup`)

## Backup Location

Backups are written inside the PostgreSQL container:
- Default path: `/backup/<database_name>.dump`
- Format: PostgreSQL custom format (compressed)
- Compression: Level 9 (maximum)
- Naming: Each database gets its own `.dump` file

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
