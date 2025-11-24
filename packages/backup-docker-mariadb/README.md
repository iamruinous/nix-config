# backup-docker-mariadb

A NixOS package and module for backing up MariaDB databases running in Docker containers.

## Overview

This package provides a shell script that automatically backs up all MariaDB databases (except system databases) from a Docker container to a specified backup directory.

## Features

- Automatic discovery of all databases in the MariaDB container
- Skips system databases (information_schema, performance_schema, mysql, sys)
- Creates SQL dump backups using `mariadb-dump`
- Includes integrated NixOS module with systemd service and timer
- Runs daily at 01:30 by default
- Supports authentication via environment variables

## Usage

### As a Standalone Package

Build and run the backup script directly:

```bash
# Build the package
nix build .#backup-docker-mariadb

# Set the root password and run
export MARIADB_ROOT_PASSWORD="your_password"
./result/bin/backup-docker-mariadb
```

### As a NixOS Module

Enable the backup service in your NixOS configuration:

```nix
{
  # Enable MariaDB Docker backup
  ruinous.mariadb.docker.backup.enable = true;

  # Provide credentials via environment file
  systemd.services.mariadb-backup.serviceConfig.EnvironmentFile = "/run/secrets/mariadb-env";
}
```

The environment file should contain:
```bash
MARIADB_ROOT_PASSWORD=your_secure_password
```

This will automatically:
- Install the backup script
- Create a systemd service (`mariadb-backup.service`)
- Create a systemd timer that runs daily at 01:30
- Persist the timer across reboots

## Requirements

- Docker container named `mariadb` must be running
- MariaDB container must have a `root` user with appropriate permissions
- Backup directory `/backup` must exist and be writable
- `MARIADB_ROOT_PASSWORD` environment variable must be set

## Backup Location

Backups are written to `/backup` on the host system:
- Format: `/backup/<database_name>.dump`
- Format: SQL dump (text format)
- Naming: Each database gets its own `.dump` file

## Environment Variables

### Required

- `MARIADB_ROOT_PASSWORD`: The password for the MariaDB root user

### Optional

- `DB_USER`: Database user (default: `root`)
- `BACKUP_DIR`: Backup directory (default: `/backup`)

## Customization

### Change Backup Schedule

Override the timer configuration in your NixOS config:

```nix
{
  systemd.timers.mariadb-backup.timerConfig.OnCalendar = "*-*-* 03:00:00";  # 3 AM
}
```

### Secure Password Management

Use agenix or another secrets management solution:

```nix
{
  age.secrets.mariadb-backup-env = {
    file = ../secrets/mariadb-backup-env.age;
    mode = "400";
  };

  systemd.services.mariadb-backup.serviceConfig.EnvironmentFile =
    config.age.secrets.mariadb-backup-env.path;
}
```

### Custom Backup Directory

Override the backup directory in the environment file:

```bash
MARIADB_ROOT_PASSWORD=your_secure_password
BACKUP_DIR=/custom/backup/location
```

## Technical Details

### Database Exclusions

The following system databases are excluded from backups:
- `information_schema` - MySQL system metadata
- `performance_schema` - MySQL performance monitoring
- `mysql` - MySQL system database
- `sys` - MySQL system database

### Backup Command

Each database is backed up using:
```bash
docker exec mariadb mariadb-dump \
  -u"$DB_USER" \
  -p"$DB_PASSWORD" \
  --databases "$DB_NAME" \
  > "$BACKUP_DIR/$DB_NAME.dump"
```

## Monitoring

Check the status of the backup service:

```bash
# View service status
systemctl status mariadb-backup.service

# View timer status
systemctl status mariadb-backup.timer

# View recent logs
journalctl -u mariadb-backup.service -n 50

# Check next scheduled run
systemctl list-timers mariadb-backup.timer
```

## Restoring from Backup

To restore a database from a backup:

```bash
# Restore directly
docker exec -i mariadb mysql -u root -p"$MARIADB_ROOT_PASSWORD" < /backup/mydb.dump

# Or copy and restore
docker cp /backup/mydb.dump mariadb:/tmp/
docker exec mariadb mysql -u root -p"$MARIADB_ROOT_PASSWORD" < /tmp/mydb.dump
```

## Security Considerations

1. **Password Storage**: Never store passwords in plain text in your configuration. Use:
   - agenix for encrypted secrets
   - systemd EnvironmentFile with restricted permissions (mode 400)
   - External secrets management systems

2. **File Permissions**: Ensure backup files have appropriate permissions:
   ```bash
   chmod 600 /backup/*.dump
   ```

3. **Backup Retention**: Implement a retention policy to remove old backups:
   ```nix
   systemd.services.mariadb-backup-cleanup = {
     script = "find /backup -name '*.dump' -mtime +30 -delete";
     startAt = "weekly";
   };
   ```

## Troubleshooting

### Authentication Issues

If you see authentication errors:
1. Verify the `MARIADB_ROOT_PASSWORD` is correct
2. Check that the environment file is readable by the service
3. Verify the MariaDB container is running: `docker ps | grep mariadb`

### Backup Directory Issues

If backups fail to write:
1. Verify the backup directory exists: `ls -la /backup`
2. Check directory permissions
3. Ensure sufficient disk space: `df -h /backup`

### Container Connection Issues

If the script can't connect to the container:
1. Verify container name: `docker ps --format '{{.Names}}'`
2. Check if MariaDB is responsive: `docker exec mariadb mysqladmin ping`

## See Also

- [backup-docker-postgres](../backup-docker-postgres/) - Similar backup solution for PostgreSQL
- [NixOS systemd services](https://nixos.org/manual/nixos/stable/#sect-systemd-services)
- [MariaDB backup documentation](https://mariadb.com/kb/en/backup-and-restore-overview/)
