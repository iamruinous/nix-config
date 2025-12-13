# tty-ruinous-social

NixOS VPS server running containerized services with backup and monitoring.

## Hardware

- **Provider**: Linode 8GB Shared Plan
- **Platform**: x86_64-linux
- **Type**: Virtual machine (QEMU guest)
- **CPU**: 4 CPU cores
- **Memory**: 8 GB RAM
- **Region**: Fremont, CA
- **Network**: Single ethernet (eth0) with DHCP
- **Storage**: Btrfs with multiple subvolumes
- **Console**: Serial console at 19200 baud

## Key Features

### Storage Configuration
- Btrfs root filesystem with subvolumes:
  - `@rootfs` - Root filesystem
  - `@boot` - Boot partition
  - `@nix` - Nix store (compressed with zstd, noatime)
  - `@data` - Data storage (compressed with zstd)
  - `@home` - Home directories (compressed with zstd)

### Bootloader
- GRUB with serial console support
- Configured for headless operation via serial port

### Containerized Services

**Infrastructure:**
- **Caddy**: Reverse proxy with Cloudflare DNS and HTTPS
- **PostgreSQL 17**: Relational database
- **Redis**: In-memory data store

**Social & Communication:**
- **Mastodon**: Federated social network (web, streaming, sidekiq)
- **Matrix Synapse**: Federated chat server with Maubot
- **WriteFreely**: Federated blogging platform

**Productivity:**
- **Baikal**: CalDAV/CardDAV server
- **Mealie**: Recipe manager
- **Karakeep**: Bookmark manager with Meilisearch

**Remote Access:**
- **RustDesk**: Self-hosted remote desktop (hbbs + hbbr)

**Other:**
- **AlbyHub**: Bitcoin Lightning wallet

### Services
- **Backup**: PostgreSQL Docker backup with Restic to terranas
- **Monitoring**: Grafana Alloy for observability and journal logging
- **VPN**: Tailscale client for secure access

### Network Configuration
- Predictable interface names disabled
- eth0 interface with DHCP
- Firewall enabled
- Tailscale routing features enabled

### Development
- Developer tools and environment
- System monitoring tools: inetutils, mtr, sysstat

## Purpose

VPS/cloud server for hosting containerized applications and services. Configured for remote management via serial console and Tailscale VPN. Runs production services with automated PostgreSQL backups and comprehensive monitoring. The headless setup with serial console makes it suitable for cloud/VPS environments.
