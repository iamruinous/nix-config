# chassis

**Primary AI Development Hub and Software Development Workstation**

Framework Desktop workstation running NixOS with secure boot. This is our main development system for creating code and managing infrastructure, available both locally and via SSH/tmux for remote development in a consistent environment.

## Hardware

- **Model**: Framework Desktop Max+ 395
- **Platform**: x86_64-linux
- **CPU**: AMD Ryzen AI Max+ 395 (16 Zen 5 cores, 32 threads, 3.0-5.1 GHz)
- **Memory**: 128GB LPDDR5x-8000
- **GPU**: Radeon 8060S (40 RDNA 3.5 Compute Units, up to 2.9 GHz)
- **NPU**: 50 TOPS AI accelerator (126 TOPS total AI performance)
- **Storage**: NVMe with Disko management (btrfs), 200GB Windows partition
- **Security**: Secure Boot via Lanzaboote

## Key Features

### AI Development Hub

Chassis serves as the primary host for OpenCode web services, providing always-on AI coding assistance accessible from anywhere:

| Project | URL | Description |
|---------|-----|-------------|
| nix | nix.oc.ruinous.ai | NixOS configuration development |
| codey | codey.oc.ruinous.ai | Codey agent system development |
| dossiq | dossiq.oc.ruinous.ai | Dossiq AI development |
| n8n-agent | n8n-agent.oc.ruinous.ai | n8n agent development |
| messy-bot | messy-bot.oc.ruinous.ai | Messy Discord bot development |
| kimaki-discord | kimaki-discord.oc.ruinous.ai | Kimaki Discord voice bot development |

Services are exposed via native Caddy with Cloudflare DNS for ACME certificates.

### Remote Development

- **SSH Access**: Full SSH access with remote forwarding enabled
- **tmux Sessions**: Pre-configured tmuxp sessions for each project
- **KDE Remote Desktop**: VNC access via krfb (port 5900)
- **Consistent Environment**: Same development setup whether local or remote

### Boot & Security

- Lanzaboote secure boot with PKI bundle
- Separate EFI and boot partitions (XBOOTLDR)
- Firmware updates via fwupd

### Storage Layout (Disko)

- **ESP**: 1GB EFI System Partition
- **Windows**: 200GB NTFS partition (dual-boot)
- **Root**: Btrfs with subvolumes:
  - `/rootfs` - Root filesystem
  - `/home` - Home directories (zstd compression)
  - `/nix` - Nix store (zstd compression, noatime)
  - `/data` - Data storage (zstd compression)
  - `/data/docker` - Docker data
  - `/data/backup` - Backups
  - `/swap` - Swap files

### User Environment

- OpenCode with multiple project configurations
- Todoist sync integration
- Vdirsyncer calendar/contacts sync
- KDE Plasma 6 desktop environment
- WezTerm terminal emulator

### Hardware Support

- Framework Desktop-specific hardware module
- AMD microcode updates
- Redistributable firmware enabled

## Purpose

High-performance desktop workstation serving as the primary AI development hub. Provides:

1. **Local Development**: Full KDE Plasma 6 desktop with development tools
2. **Remote Development**: SSH/tmux access for consistent development from any device
3. **AI Assistance**: Always-on OpenCode web services for AI-powered coding
4. **Infrastructure Management**: Central point for managing NixOS configurations

Features dual-boot capability with Windows and comprehensive NixOS configuration with secure boot.

## Network Services

| Port | Service | Description |
|------|---------|-------------|
| 22 | SSH | Remote shell access |
| 80/443 | Caddy | HTTPS reverse proxy for OpenCode |
| 5900 | KDE Remote Desktop | VNC screen sharing |

## Quick Start

### Remote Development

```bash
# SSH into chassis
ssh chassis

# Start a project session
tmuxp load nix      # NixOS config development
tmuxp load codey    # Codey agent development
tmuxp load dossiq   # Dossiq AI development
```

### Web Access

Access OpenCode web UI for any project at `https://<project>.oc.ruinous.ai`
