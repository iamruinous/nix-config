# microvm-transfer

Transfer MicroVMs between hosts via SSH.

## Overview

This tool transfers MicroVM persistent data between NixOS hosts using SSH and rsync. It's designed to work with the directory structure in `/persistent/microvms/`.

## Usage

```bash
# Send a VM to a remote host
microvm-transfer send messy-tty user@newhost

# Send with overlay image
microvm-transfer send -o messy-tty user@newhost

# Stop VM before sending (recommended)
microvm-transfer send -s messy-tty user@newhost

# Receive a VM from a remote host
microvm-transfer receive user@oldhost messy-tty

# Dry-run to preview
microvm-transfer send -n messy-tty user@newhost

# Custom SSH port
microvm-transfer send -p 2222 messy-tty user@newhost
```

## Options

| Option | Description |
|--------|-------------|
| `-n, --dry-run` | Show what would be done |
| `-v, --verbose` | Enable verbose output |
| `-o, --overlay` | Include nix-store overlay image |
| `-s, --stop` | Stop VM before transfer |
| `-b, --base <path>` | MicroVM data path (default: `/persistent/microvms`) |
| `-p, --port <port>` | SSH port (default: 22) |

## Migration Workflow

### On the Source Host (obelisk)

1. **Create a local backup first:**
   ```bash
   microvm-backup backup messy-tty
   ```

2. **Send to the new host:**
   ```bash
   microvm-transfer send -s messy-tty user@newhost
   ```

### On the Destination Host

1. **Ensure NixOS configuration includes the MicroVM:**
   ```nix
   microvm.vms.messy-tty = {
     inherit flake;
     updateFlake = "...";
   };

   systemd.tmpfiles.rules = [
     "d /persistent/microvms/messy-tty/persistent 0770 root root -"
   ];
   ```

2. **Rebuild and start:**
   ```bash
   sudo nixos-rebuild switch --flake .#hostname
   sudo systemctl start microvm@messy-tty
   ```

## Network Considerations

- Ensure SSH access between hosts
- The remote user needs sudo access for creating directories
- Both hosts should have rsync installed (it is a dependency of this tool)

## See Also

- `microvm-backup` - Local backup operations
