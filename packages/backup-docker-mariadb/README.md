# backup-docker-mariadb

A NixOS package and module for backing up MariaDB databases running in Docker containers.

## Overview

This package provides a shell script that automatically backs up all MariaDB databases (except system databases) from a Docker container to a specified backup directory. The package uses template substitution to allow configuration of container name, backup directory, user, and excluded databases.

## Features

- Automatic discovery of all databases in the MariaDB container
- Configurable list of excluded databases (system databases by default)
- Creates SQL dump backups using `mariadb-dump`
- Integrated NixOS module with systemd service and timer
- Customizable backup schedule (daily at 01:30 by default)
- Template-based configuration for reproducible builds
- Supports authentication via environment variables

## Package Structure

The package follows the standard template substitution pattern:

- `default.nix`: Package definition using `stdenv.mkDerivation`
- `backup-docker-mariadb.sh`: Shell script template with `@variable@` placeholders
- Configuration values are substituted at build time for reproducible builds

## Usage

### As a Standalone Package

Build and run the backup script directly with default configuration:

```bash
# Build the package with defaults
nix build .#backup-docker-mariadb

# Set the root password and run
export MARIADB_ROOT_PASSWORD="your_password"
./result/bin/backup-docker-mariadb
```

Build with custom configuration:

```bash
# Build with custom settings
nix build .#backup-docker-mariadb --override-input containerName my-mariadb
```

### As a NixOS Module

Enable the backup service in your NixOS configuration with default settings:

```nix
{
  # Enable MariaDB Docker backup with defaults
  ruinous.mariadb.docker.backup.enable = true;

  # Provide credentials via environment file
  ruinous.mariadb.docker.backup.serviceConfig.EnvironmentFile =
    "/run/secrets/mariadb-backup-env";
}
```

## Module Options

### ruinous.mariadb.docker.backup.enable

**Type:** `boolean`

**Default:** `false`

**Description:** Whether to enable the MariaDB Docker backup service.

**Example:**
```nix
ruinous.mariadb.docker.backup.enable = true;
```

### ruinous.mariadb.docker.backup.containerName

**Type:** `string`

**Default:** `"mariadb"`

**Description:** Name of the Docker container running MariaDB.

**Example:**
```nix
ruinous.mariadb.docker.backup.containerName = "my-mariadb";
```

### ruinous.mariadb.docker.backup.backupDir

**Type:** `string`

**Default:** `"/backup"`

**Description:** Directory path on the host where backups will be stored.

**Example:**
```nix
ruinous.mariadb.docker.backup.backupDir = "/var/backups/mariadb";
```

### ruinous.mariadb.docker.backup.mariadbUser

**Type:** `string`

**Default:** `"root"`

**Description:** MariaDB user to use for backup operations. Must have privileges to list and dump all databases.

**Example:**
```nix
ruinous.mariadb.docker.backup.mariadbUser = "backup_user";
```

### ruinous.mariadb.docker.backup.excludedDatabases

**Type:** `list of string`

**Default:** `["information_schema" "performance_schema" "mysql" "sys"]`

**Description:** List of database names to exclude from backups. System databases are excluded by default.

**Example:**
```nix
ruinous.mariadb.docker.backup.excludedDatabases = [
  "information_schema"
  "performance_schema"
  "mysql"
  "sys"
  "test_db"
];
```

### ruinous.mariadb.docker.backup.schedule

**Type:** `string`

**Default:** `"*-*-* 01:30:00"`

**Description:** Systemd timer schedule in OnCalendar format. Controls when backups are performed.

**Example:**
```nix
# Run at 2:30 AM every day
ruinous.mariadb.docker.backup.schedule = "*-*-* 02:30:00";

# Run twice daily at 2 AM and 2 PM
ruinous.mariadb.docker.backup.schedule = "*-*-* 02,14:00:00";

# Run weekly on Sunday at 3 AM
ruinous.mariadb.docker.backup.schedule = "Sun *-*-* 03:00:00";
```

### ruinous.mariadb.docker.backup.persistent

**Type:** `boolean`

**Default:** `true`

**Description:** Whether to run missed backups if the system was off during the scheduled time. When true, systemd will run the backup as soon as possible after the system comes back online.

**Example:**
```nix
ruinous.mariadb.docker.backup.persistent = false;
```

### ruinous.mariadb.docker.backup.serviceConfig

**Type:** `attribute set`

**Default:** `{}`

**Description:** Additional systemd service configuration options. Commonly used to set environment files, user permissions, or other service-specific settings.

**Example:**
```nix
ruinous.mariadb.docker.backup.serviceConfig = {
  EnvironmentFile = "/run/secrets/mariadb-backup-env";
  User = "backup";
  Group = "backup";
};
```

## Complete Configuration Examples

### Basic Setup

```nix
{
  # Minimal configuration with defaults
  ruinous.mariadb.docker.backup = {
    enable = true;
    serviceConfig.EnvironmentFile = "/run/secrets/mariadb-env";
  };
}
```

### Custom Container and Schedule

```nix
{
  ruinous.mariadb.docker.backup = {
    enable = true;
    containerName = "production-mariadb";
    backupDir = "/mnt/backups/mariadb";
    schedule = "*-*-* 03:00:00";  # 3 AM daily
    serviceConfig.EnvironmentFile = config.age.secrets.mariadb-backup-env.path;
  };
}
```

### Multiple Excluded Databases

```nix
{
  ruinous.mariadb.docker.backup = {
    enable = true;
    excludedDatabases = [
      "information_schema"
      "performance_schema"
      "mysql"
      "sys"
      "test_database"
      "legacy_db"
    ];
    serviceConfig.EnvironmentFile = "/run/secrets/mariadb-env";
  };
}
```

### With Agenix Secrets

```nix
{ config, ... }:
{
  # Define the secret
  age.secrets.mariadb-backup-env = {
    file = ../secrets/mariadb-backup-env.age;
    mode = "400";
  };

  # Configure backup with secret
  ruinous.mariadb.docker.backup = {
    enable = true;
    containerName = "mariadb";
    backupDir = "/var/backups/mariadb";
    schedule = "*-*-* 02:00:00";
    serviceConfig.EnvironmentFile = config.age.secrets.mariadb-backup-env.path;
  };
}
```

## Environment Variables

### Required

- `MARIADB_ROOT_PASSWORD`: The password for the MariaDB user specified in `mariadbUser` option

### Environment File Format

The environment file should contain:
```bash
MARIADB_ROOT_PASSWORD=your_secure_password
```

**Important:** Use agenix or another secrets management solution to securely store the environment file. Never commit plain text passwords.

## Backup Location

Backups are written to the directory specified by `backupDir` (default: `/backup`):
- **Format:** SQL dump files
- **Naming:** `<database_name>.dump`
- **Location:** Each database gets its own dump file

**Example:**
```
/backup/
├── app_database.dump
├── wordpress.dump
└── nextcloud.dump
```

## Requirements

- Docker container with MariaDB must be running
- Container name must match the `containerName` option
- MariaDB user must have privileges to:
  - List all databases (`SHOW DATABASES`)
  - Dump all target databases
- Backup directory must exist and be writable by the systemd service
- `MARIADB_ROOT_PASSWORD` environment variable must be set (via EnvironmentFile)

## Template Substitution

The package uses Nix's `substitute` to replace template variables at build time:

| Template Variable      | Description                    | Default Value           |
|------------------------|--------------------------------|-------------------------|
| `@docker@`             | Path to docker binary          | `${pkgs.docker}`        |
| `@containerName@`      | Docker container name          | `mariadb`               |
| `@backupDir@`          | Backup directory path          | `/backup`               |
| `@mariadbUser@`        | MariaDB user for backups       | `root`                  |
| `@excludedDatabases@`  | Comma-separated excluded DBs   | See defaults            |

This approach ensures:
- Reproducible builds (same inputs = same output)
- No runtime configuration files needed
- Configuration baked into the binary
- Can build multiple variants with different configurations

## Monitoring

### Check Service Status

```bash
# View service status
systemctl status mariadb-backup.service

# View timer status
systemctl status mariadb-backup.timer

# View recent logs
journalctl -u mariadb-backup.service -n 50

# Check next scheduled run
systemctl list-timers mariadb-backup.timer

# Follow logs in real-time
journalctl -u mariadb-backup.service -f
```

### Manual Backup

Run a backup manually without waiting for the timer:

```bash
# Trigger backup now
systemctl start mariadb-backup.service

# Check status
systemctl status mariadb-backup.service
```

## Restoring from Backup

To restore a database from a backup:

```bash
# Restore directly
docker exec -i mariadb mysql -u root -p"$MARIADB_ROOT_PASSWORD" < /backup/mydb.dump

# Or copy and restore
docker cp /backup/mydb.dump mariadb:/tmp/
docker exec mariadb mysql -u root -p"$MARIADB_ROOT_PASSWORD" < /tmp/mydb.dump

# Restore specific database
docker exec -i mariadb mysql -u root -p"$MARIADB_ROOT_PASSWORD" database_name < /backup/mydb.dump
```

## Security Considerations

### Password Storage

**Never** store passwords in plain text. Use one of these approaches:

1. **Agenix (Recommended)**
   ```nix
   age.secrets.mariadb-backup-env = {
     file = ../secrets/mariadb-backup-env.age;
     mode = "400";
   };

   ruinous.mariadb.docker.backup.serviceConfig.EnvironmentFile =
     config.age.secrets.mariadb-backup-env.path;
   ```

2. **Systemd EnvironmentFile with Restricted Permissions**
   ```bash
   # Create environment file
   echo "MARIADB_ROOT_PASSWORD=secret" > /run/secrets/mariadb-env
   chmod 400 /run/secrets/mariadb-env
   chown root:root /run/secrets/mariadb-env
   ```

### File Permissions

Ensure backup files have appropriate permissions:

```bash
# Restrict backup file access
chmod 600 /backup/*.dump
chown root:root /backup/*.dump

# Or use systemd service configuration
ruinous.mariadb.docker.backup.serviceConfig = {
  User = "backup";
  Group = "backup";
  UMask = "0077";  # Creates files with 600 permissions
};
```

### Backup Retention

Implement a retention policy to remove old backups:

```nix
{
  systemd.services.mariadb-backup-cleanup = {
    description = "Clean up old MariaDB backups";
    script = ''
      # Remove backups older than 30 days
      ${pkgs.findutils}/bin/find /backup -name '*.dump' -mtime +30 -delete
    '';
    startAt = "weekly";
  };
}
```

## Troubleshooting

### Authentication Issues

**Symptoms:** Authentication errors, access denied messages

**Solutions:**
1. Verify the `MARIADB_ROOT_PASSWORD` is correct
2. Check that the environment file is readable by the service:
   ```bash
   ls -la /run/secrets/mariadb-backup-env
   ```
3. Verify the MariaDB container is running:
   ```bash
   docker ps | grep mariadb
   ```
4. Test manual authentication:
   ```bash
   docker exec mariadb mysql -u root -p"$MARIADB_ROOT_PASSWORD" -e "SHOW DATABASES;"
   ```

### Backup Directory Issues

**Symptoms:** Permission denied, no such file or directory

**Solutions:**
1. Verify the backup directory exists:
   ```bash
   ls -la /backup
   ```
2. Check directory permissions:
   ```bash
   # Directory should be writable by the service user
   chmod 755 /backup
   ```
3. Ensure sufficient disk space:
   ```bash
   df -h /backup
   ```

### Container Connection Issues

**Symptoms:** Cannot connect to container, container not found

**Solutions:**
1. Verify container name matches configuration:
   ```bash
   docker ps --format '{{.Names}}' | grep mariadb
   ```
2. Check if container is running:
   ```bash
   docker ps | grep mariadb
   ```
3. Test container connectivity:
   ```bash
   docker exec mariadb mysqladmin ping
   ```

### Timer Not Running

**Symptoms:** Backups not happening on schedule

**Solutions:**
1. Check timer status:
   ```bash
   systemctl status mariadb-backup.timer
   ```
2. Verify timer is enabled:
   ```bash
   systemctl is-enabled mariadb-backup.timer
   ```
3. Check systemd timer list:
   ```bash
   systemctl list-timers mariadb-backup.timer
   ```
4. Manually enable if needed:
   ```bash
   systemctl enable --now mariadb-backup.timer
   ```

## Building and Testing

### Build the Package

```bash
# Build with defaults
nix build .#backup-docker-mariadb

# Build with custom configuration
nix build .#backup-docker-mariadb --override-input containerName my-mariadb

# Test the built script
export MARIADB_ROOT_PASSWORD="test"
./result/bin/backup-docker-mariadb
```

### Test the Module

```bash
# Dry-build to check for syntax errors
nixos-rebuild dry-build --flake .#hostname

# Build and activate (test system only!)
nixos-rebuild test --flake .#hostname

# Check the generated systemd units
systemctl cat mariadb-backup.service
systemctl cat mariadb-backup.timer
```

## Package Customization

The package can be customized via override:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.backup-docker-mariadb.override {
      containerName = "custom-mariadb";
      backupDir = "/mnt/backups";
      mariadbUser = "backup_user";
      excludedDatabases = [ "mysql" "sys" "test" ];
    })
  ];
}
```

This creates a new package with the specified configuration baked in at build time.

## Comparison with backup-docker-postgres

This package follows the same structure and patterns as `backup-docker-postgres`:

| Feature                      | MariaDB                  | PostgreSQL               |
|------------------------------|--------------------------|--------------------------|
| Builder                      | stdenv.mkDerivation      | stdenv.mkDerivation      |
| Template substitution        | Yes                      | Yes                      |
| Separate module              | Yes                      | Yes                      |
| Configurable options         | Yes (8 options)          | Yes (8 options)          |
| Default schedule             | 01:30                    | 01:00                    |
| Default user                 | root                     | postgres                 |
| Excluded DBs by default      | 4 system DBs             | 4 template DBs           |

## See Also

- [backup-docker-postgres](../backup-docker-postgres/) - Similar backup solution for PostgreSQL
- [NixOS systemd services](https://nixos.org/manual/nixos/stable/#sect-systemd-services)
- [MariaDB backup documentation](https://mariadb.com/kb/en/backup-and-restore-overview/)
- [Systemd timer OnCalendar format](https://www.freedesktop.org/software/systemd/man/systemd.time.html)
