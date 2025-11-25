# backup-docker-postgres

A NixOS package and module for backing up PostgreSQL databases running in Docker containers.

## Overview

This package provides a shell script that automatically backs up all PostgreSQL databases (except system databases) from a Docker container to a specified backup directory. The package uses template substitution to allow configuration of container name, backup directory, user, and excluded databases.

## Features

- Automatic discovery of all databases in the PostgreSQL container
- Configurable list of excluded databases (system databases by default)
- Creates compressed backups using `pg_dump` custom format (`-Fc -Z 9`)
- Integrated NixOS module with systemd service and timer
- Customizable backup schedule (daily at 01:00 by default)
- Template-based configuration for reproducible builds

## Package Structure

The package follows the standard template substitution pattern:

- `default.nix`: Package definition using `stdenv.mkDerivation`
- `backup-docker-postgres.sh`: Shell script template with `@variable@` placeholders
- Configuration values are substituted at build time for reproducible builds

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

Enable the backup service in your NixOS configuration with default settings:

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

### ruinous.postgres.docker.backup.enable

**Type:** `boolean`

**Default:** `false`

**Description:** Whether to enable the PostgreSQL Docker backup service.

**Example:**
```nix
ruinous.postgres.docker.backup.enable = true;
```

### ruinous.postgres.docker.backup.containerName

**Type:** `string`

**Default:** `"postgres"`

**Description:** Name of the Docker container running PostgreSQL.

**Example:**
```nix
ruinous.postgres.docker.backup.containerName = "my-postgres";
```

### ruinous.postgres.docker.backup.backupDir

**Type:** `string`

**Default:** `"/backup"`

**Description:** Directory path inside the container where backups will be stored.

**Example:**
```nix
ruinous.postgres.docker.backup.backupDir = "/var/backups/postgres";
```

### ruinous.postgres.docker.backup.postgresUser

**Type:** `string`

**Default:** `"postgres"`

**Description:** PostgreSQL user to use for backup operations. Must have privileges to list and dump all databases.

**Example:**
```nix
ruinous.postgres.docker.backup.postgresUser = "backup_user";
```

### ruinous.postgres.docker.backup.excludedDatabases

**Type:** `list of string`

**Default:** `["template0" "template1" "postgres" "postgres=CTc/postgres"]`

**Description:** List of database names to exclude from backups. System databases are excluded by default.

**Example:**
```nix
ruinous.postgres.docker.backup.excludedDatabases = [
  "template0"
  "template1"
  "postgres"
  "postgres=CTc/postgres"
  "test_db"
];
```

### ruinous.postgres.docker.backup.schedule

**Type:** `string`

**Default:** `"*-*-* 01:00:00"`

**Description:** Systemd timer schedule in OnCalendar format. Controls when backups are performed.

**Example:**
```nix
# Run at 2:30 AM every day
ruinous.postgres.docker.backup.schedule = "*-*-* 02:30:00";

# Run twice daily at 2 AM and 2 PM
ruinous.postgres.docker.backup.schedule = "*-*-* 02,14:00:00";

# Run weekly on Sunday at 3 AM
ruinous.postgres.docker.backup.schedule = "Sun *-*-* 03:00:00";
```

### ruinous.postgres.docker.backup.persistent

**Type:** `boolean`

**Default:** `true`

**Description:** Whether to run missed backups if the system was off during the scheduled time. When true, systemd will run the backup as soon as possible after the system comes back online.

**Example:**
```nix
ruinous.postgres.docker.backup.persistent = false;
```

### ruinous.postgres.docker.backup.serviceConfig

**Type:** `attribute set`

**Default:** `{}`

**Description:** Additional systemd service configuration options. Commonly used to set environment files, user permissions, or other service-specific settings.

**Example:**
```nix
ruinous.postgres.docker.backup.serviceConfig = {
  EnvironmentFile = "/run/secrets/postgres-backup-env";
  User = "backup";
  Group = "backup";
};
```

## Complete Configuration Examples

### Basic Setup

```nix
{
  # Minimal configuration with defaults
  ruinous.postgres.docker.backup.enable = true;
}
```

### Custom Container and Schedule

```nix
{
  ruinous.postgres.docker.backup = {
    enable = true;
    containerName = "production-postgres";
    backupDir = "/mnt/backups/postgres";
    schedule = "*-*-* 03:00:00";  # 3 AM daily
  };
}
```

### Multiple Excluded Databases

```nix
{
  ruinous.postgres.docker.backup = {
    enable = true;
    excludedDatabases = [
      "template0"
      "template1"
      "postgres"
      "postgres=CTc/postgres"
      "test_database"
      "legacy_db"
    ];
  };
}
```

### With Additional Service Configuration

```nix
{
  ruinous.postgres.docker.backup = {
    enable = true;
    serviceConfig = {
      EnvironmentFile = "/run/secrets/postgres-backup-env";
      User = "backup";
      Group = "backup";
    };
  };
}
```

## Backup Location

Backups are written to the directory specified by `backupDir` (default: `/backup`):
- **Format:** PostgreSQL custom format (compressed)
- **Compression:** Level 9 (maximum)
- **Naming:** `<database_name>.dump`
- **Location:** Each database gets its own dump file

**Example:**
```
/backup/
├── app_database.dump
├── nextcloud.dump
└── keycloak.dump
```

## Requirements

- Docker container with PostgreSQL must be running
- Container name must match the `containerName` option
- PostgreSQL user must have privileges to:
  - List all databases (`\l`)
  - Dump all target databases
- Backup directory must exist and be writable inside the container

## Template Substitution

The package uses Nix's `substitute` to replace template variables at build time:

| Template Variable      | Description                    | Default Value           |
|------------------------|--------------------------------|-------------------------|
| `@docker@`             | Path to docker binary          | `${pkgs.docker}`        |
| `@containerName@`      | Docker container name          | `postgres`              |
| `@backupDir@`          | Backup directory path          | `/backup`               |
| `@postgresUser@`       | PostgreSQL user for backups    | `postgres`              |
| `@excludedDatabases@`  | Comma-separated excluded DBs   | See defaults            |

This approach ensures:
- Reproducible builds (same inputs = same output)
- No runtime configuration files needed
- Configuration baked into the binary
- Can build multiple variants with different configurations

## Technical Details

### Database Exclusions

The following databases are excluded from backups by default:
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

**Flags:**
- `-Fc`: Custom format (compressed and restorable with pg_restore)
- `-Z 9`: Maximum compression level
- `--no-owner`: Don't output ownership commands
- `--no-privileges`: Don't output privilege commands

## Monitoring

### Check Service Status

```bash
# View service status
systemctl status postgres-backup.service

# View timer status
systemctl status postgres-backup.timer

# View recent logs
journalctl -u postgres-backup.service -n 50

# Check next scheduled run
systemctl list-timers postgres-backup.timer

# Follow logs in real-time
journalctl -u postgres-backup.service -f
```

### Manual Backup

Run a backup manually without waiting for the timer:

```bash
# Trigger backup now
systemctl start postgres-backup.service

# Check status
systemctl status postgres-backup.service
```

## Restoring from Backup

To restore a database from a backup:

```bash
# Restore directly if backup is in container
docker exec postgres pg_restore \
  -U postgres \
  -d mydb \
  --clean \
  /backup/mydb.dump

# Or create a new database and restore
docker exec postgres createdb -U postgres mydb_restored
docker exec postgres pg_restore \
  -U postgres \
  -d mydb_restored \
  /backup/mydb.dump

# Restore from host to container
docker cp /backup/mydb.dump postgres:/tmp/
docker exec postgres pg_restore \
  -U postgres \
  -d mydb \
  /tmp/mydb.dump
```

## Building and Testing

### Build the Package

```bash
# Build with defaults
nix build .#backup-docker-postgres

# Test the built script
./result/bin/backup-docker-postgres

# Build with custom configuration
nix build .#backup-docker-postgres --override-input containerName my-postgres
```

### Test the Module

```bash
# Dry-build to check for syntax errors
nixos-rebuild dry-build --flake .#hostname

# Build and activate (test system only!)
nixos-rebuild test --flake .#hostname

# Check the generated systemd units
systemctl cat postgres-backup.service
systemctl cat postgres-backup.timer
```

## Package Customization

The package can be customized via override:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.backup-docker-postgres.override {
      containerName = "custom-postgres";
      backupDir = "/mnt/backups";
      postgresUser = "backup_user";
      excludedDatabases = [ "template0" "template1" "test" ];
    })
  ];
}
```

This creates a new package with the specified configuration baked in at build time.

## Comparison with backup-docker-mariadb

This package follows the same structure and patterns as `backup-docker-mariadb`:

| Feature                      | PostgreSQL               | MariaDB                  |
|------------------------------|--------------------------|--------------------------|
| Builder                      | stdenv.mkDerivation      | stdenv.mkDerivation      |
| Template substitution        | Yes                      | Yes                      |
| Separate module              | Yes                      | Yes                      |
| Configurable options         | Yes (8 options)          | Yes (8 options)          |
| Default schedule             | 01:00                    | 01:30                    |
| Default user                 | postgres                 | root                     |
| Excluded DBs by default      | 4 template DBs           | 4 system DBs             |
| Backup format                | Custom compressed        | SQL dump                 |

## See Also

- [backup-docker-mariadb](../backup-docker-mariadb/) - Similar backup solution for MariaDB
- [NixOS systemd services](https://nixos.org/manual/nixos/stable/#sect-systemd-services)
- [PostgreSQL backup documentation](https://www.postgresql.org/docs/current/backup.html)
- [Systemd timer OnCalendar format](https://www.freedesktop.org/software/systemd/man/systemd.time.html)
