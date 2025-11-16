# monolith

Primary NixOS server for infrastructure services, containers, and network services.

## Hardware

- **Model**: Minisforum MS-01
- **Platform**: x86_64-linux
- **CPU**: Intel 13th Gen i9-13900H (24 cores, KVM support)
- **Memory**: 96 GB RAM
- **Network**: Dual 2.5GbE ethernet (enp2s0f0np0, enp2s0f1np1), VLAN support, Thunderbolt
- **Storage**: Disko-managed storage with NVMe
- **Special Hardware**: Google Gasket kernel module support

## Key Features

### Networking
- VLAN 2 (services network): 10.55.20.24/24
- systemd-networkd configuration
- nftables firewall
- Cloudflared tunnels
- Tailscale VPN with subnet routing (10.55.0.0/16)

### Virtualization & Containers
- Docker with container orchestration
- Multiple containerized services (defined in containers.nix)
- nix-ld for running binary applications

### Services
- **Printing**: CUPS with network printer discovery
- **Backup**:
  - MariaDB Docker backup
  - Restic backups to terranas
- **Monitoring**: Grafana Alloy for observability and journal logging
- **NFS**: Network file sharing
- **SSH**: Custom SSH configuration
- **RTL_433**: SDR for 433MHz devices
- **Caddy**: Certificate management and copying

### Security & Management
- Plymouth boot splash
- Firmware updates via fwupd

### Development
- Developer tools and environment

## Purpose

Main infrastructure server hosting critical services including databases, containers, network services, and backups. Acts as a central hub for the home network with Tailscale subnet routing, printer services, and monitoring infrastructure. Also serves as a host for containerized applications and provides NFS storage.
