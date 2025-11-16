# pilaster

Lightweight NixOS server for Docker containers and network services.

## Hardware

- **Model**: Minisforum MS-01
- **Platform**: x86_64-linux
- **CPU**: Intel 13th Gen i9-13900H (24 cores, KVM support)
- **Memory**: 96 GB RAM
- **Network**: Dual 2.5GbE ethernet, VLAN 2 support, Thunderbolt
- **Storage**: NVMe with Disko management
- **IP Address**: 10.55.20.25/24 (VLAN 2)

## Key Features

### Networking
- VLAN 2 (services network): 10.55.20.25/24
- systemd-networkd configuration
- nftables firewall
- Tailscale VPN with subnet routing (10.55.0.0/16)

### Services
- **Docker**: Container runtime
- **NFS**: Network file storage
- **Backup**: Restic backups to terranas
- **Monitoring**: Grafana Alloy for observability and journal logging

### Development
- Developer tools and environment

### Security & Management
- Plymouth boot splash
- Firmware updates via fwupd

## Purpose

Streamlined server focused on running Docker containers and providing network services. Works alongside other infrastructure servers (monolith, obelisk) to distribute workloads. Configured with essential monitoring and backup capabilities while maintaining a minimal service footprint.
