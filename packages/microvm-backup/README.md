# microvm-backup

Backup MicroVM persistent data locally.

## Overview

This tool creates local backups of MicroVM persistent data stored in `/persistent/microvms/`. It supports timestamped backups, optional overlay image inclusion, and restore operations.

## Usage

```bash
# List all MicroVMs
microvm-backup list

# Check status of a VM
microvm-backup status messy-tty

# Verify data integrity
microvm-backup verify messy-tty

# Backup a single VM (creates /backup/microvms/messy-tty/<timestamp>/)
microvm-backup backup messy-tty

# Backup to custom location
microvm-backup backup messy-tty /mnt/external/vms

# Backup with overlay image
microvm-backup backup -o messy-tty

# Backup all VMs
microvm-backup backup-all

# Restore from backup
microvm-backup restore /backup/microvms/messy-tty/latest messy-tty

# Dry-run mode
microvm-backup backup -n messy-tty
```

## Options

| Option | Description |
|--------|-------------|
| `-n, --dry-run` | Show what would be done |
| `-v, --verbose` | Enable verbose output |
| `-o, --overlay` | Include nix-store overlay image |
| `-b, --base <path>` | MicroVM data path (default: `/persistent/microvms`) |
| `-d, --dest <path>` | Backup destination (default: `/backup/microvms`) |

## Backup Structure

```
/backup/microvms/
└── messy-tty/
    ├── 20241201-120000/
    │   ├── persistent/
    │   │   ├── etc/
    │   │   ├── var/
    │   │   └── home/
    │   └── nix-store-overlay.img  (if -o used)
    ├── 20241201-180000/
    │   └── ...
    └── latest -> 20241201-180000
```

## See Also

- `microvm-transfer` - Transfer MicroVMs between hosts
