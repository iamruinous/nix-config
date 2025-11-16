# messy-tty

Ephemeral NixOS MicroVM with persistent storage for development.

## Hardware

- **Physical Host**: obelisk (Alienware Aurora R16)
- **Platform**: x86_64-linux
- **Type**: MicroVM (QEMU hypervisor)
- **Resources**: 2 CPU cores, 2047 MB RAM
- **Network**: macvtap interface on VLAN 2 (MAC: 02:02:00:00:00:01)

## Key Features

### MicroVM Configuration
- QEMU-based virtualization
- Writable Nix store overlay (4GB image)
- Shared host Nix store via virtiofs (read-only)
- Persistent storage mounted at `/persistent`

### Impermanence
- Root filesystem is ephemeral (cleared on reboot)
- Selective persistence for important data:
  - User directories: Projects, .gemini, .local, .cache, .claude, .npm
  - User files: .claude.json, .cfcli.yml
  - System: machine-id, SSH host keys, /var/lib/nixos

### Development Environment
- Developer tools and environment
- Cloudflare CLI

### User Configuration
- Primary user: messy
- Persistent data stored on host at `/persistent/microvms/messy-tty/persistent`

## Purpose

Lightweight development environment for user "messy" with ephemeral root filesystem and selective persistence. The VM maintains state for projects and configuration while keeping the base system clean on each boot. Runs as a MicroVM on the obelisk host.
