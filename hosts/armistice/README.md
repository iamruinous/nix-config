# armistice

NixOS ARM server with development tools and monitoring.

## Hardware

- **Model**: Minisforum MS-R1 Workstation
- **Platform**: aarch64-linux (ARM64)
- **Memory**: 64 GB RAM
- **Storage**: 2TB Samsung 990 NVMe, Btrfs filesystem managed by Disko
- **Network**: Single ethernet interface (enp1s0) with VLAN 2
- **IP Address**: 10.55.20.23/24 (VLAN 2 services network)

## Key Features

### Storage Configuration
- Disko-managed Btrfs partitioning
- Subvolumes: rootfs, home, nix, data, swap
- Data subvolumes for Docker and KVMs
- Compressed storage with zstd

### Network Configuration
- Static IP on VLAN 2 (services network)
- Gateway: 10.55.20.1
- DNS: 10.55.10.35
- systemd-networkd with nftables firewall

### Containerized Services
- **Caddy**: Reverse proxy with Cloudflare DNS and HTTPS
- Docker with btrfs storage driver
- Container networks: servicenet, proxynet, datanet

### Services
- Grafana Alloy for observability
- Journal logging integration
- UPS power monitoring
- Plymouth boot splash

### Development Environment
- Developer tools and environment configured
- Server module for infrastructure services

## Purpose

ARM-based server providing development and infrastructure services on the services network (VLAN 2). Configured with monitoring, power management, and a full Btrfs storage layout suitable for containers and virtual machines.
