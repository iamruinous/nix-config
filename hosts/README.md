# Hosts

This directory contains configurations for all systems managed by this flake. Each host has its own subdirectory with host-specific configuration files and documentation.

## Overview

This infrastructure consists of 12 hosts spanning multiple platforms:
- **6 NixOS servers** - Infrastructure and compute nodes
- **3 NixOS MicroVMs** - Ephemeral development environments
- **3 macOS systems** - Development workstations

## Physical Infrastructure

### High-Performance Servers

#### [monolith](monolith/README.md)
**Minisforum MS-01** - Primary infrastructure server
- Intel i9-13900H (24 cores), 96 GB RAM
- Docker containers, NFS, printing, backups
- Tailscale subnet routing, Cloudflared tunnels
- RTL_433 SDR, Grafana Alloy monitoring

#### [obelisk](obelisk/README.md)
**Alienware Aurora R16** - GPU-accelerated compute server
- Intel i9-14900KF (24 cores), 64 GB DDR5, RTX 4090
- NVIDIA container toolkit for ML/AI workloads
- Hosts MicroVMs (messy-tty, ruinous-tty)
- libvirt, Docker, aarch64 emulation

#### [pilaster](pilaster/README.md)
**Minisforum MS-01** - Container server
- Intel i9-13900H (24 cores), 96 GB RAM
- Docker, NFS, Restic backups
- Tailscale, Grafana Alloy monitoring

### Thin Clients (High Availability Pair)

#### [void](void/README.md)
**Dell Wyse 5060** - VRRP MASTER
- AMD GX-424CC 2.4GHz, 4 GB RAM, 8 GB Flash
- Keepalived VRRP virtual IP: 10.55.10.34/24
- High availability master node

#### [gap](gap/README.md)
**Dell Wyse 5060** - VRRP BACKUP
- AMD GX-424CC 2.4GHz, 4 GB RAM, 8 GB Flash
- Keepalived VRRP backup for automatic failover
- Provides service continuity when master fails

### Cloud VPS

#### [tty-ruinous-social](tty-ruinous-social/README.md)
**Linode 8GB Shared Plan** - Production VPS
- 4 CPU cores, 8 GB RAM, Fremont, CA
- Containerized services with PostgreSQL backups
- Serial console, Tailscale VPN access
- Headless server configuration

## Development Environments

### MicroVMs (Running on obelisk)

#### [ruinous-tty](ruinous-tty/README.md)
**MicroVM** - Development environment for jmeskill
- 2 CPU cores, 2 GB RAM
- Ephemeral root with selective persistence
- QEMU + virtiofs for Nix store sharing

#### [messy-tty](messy-tty/README.md)
**MicroVM** - Development environment for messy
- 2 CPU cores, 2 GB RAM
- Ephemeral root with selective persistence
- Cloudflare CLI tools

### Laptop

#### [framework](framework/README.md)
**Framework Laptop 13** - Primary laptop
- Intel Core Ultra 5 125H (14 cores), 32 GB DDR5
- 1TB NVMe, Intel Arc graphics
- KDE Plasma 6, Wayland, Lanzaboote secure boot
- Steam, Flatpak, fingerprint authentication

## macOS Systems

#### [jbookpro](jbookpro/README.md)
**14-inch MacBook Pro (Space Black)** - Apple Silicon workstation
- Apple M4 (10-core CPU, 10-core GPU)
- 32 GB unified memory
- nix-darwin development environment

#### [jmacmini](jmacmini/README.md)
**Mac mini** - Apple Silicon desktop
- Apple M2 Pro (10-core CPU, 16-core GPU, 16-core Neural Engine)
- 16 GB unified memory, 512 GB SSD
- nix-darwin development environment

#### [studio](studio/README.md)
**iMac Pro 2017** - Intel workstation
- 3.2 GHz 8-Core Intel Xeon W
- 32 GB DDR4, Radeon Pro Vega 56 8 GB
- nix-darwin development environment

## Network Architecture

### VLAN Configuration
- **Management Network** (10.55.10.0/24) - gap, void
- **Services Network** (10.55.20.0/24 - VLAN 2) - monolith, obelisk, pilaster, MicroVMs

### Tailscale VPN
Multiple hosts advertise subnet routes (10.55.0.0/16):
- monolith, obelisk, pilaster (on-premises)
- tty-ruinous-social (cloud access)

### High Availability
- Virtual IP: 10.55.10.34/24
- VRRP Router ID: 35
- Master: void (priority 44)
- Backup: gap (priority 44)

## Infrastructure Services

### Backup Strategy
- **Restic** to terranas: monolith, obelisk, pilaster, tty-ruinous-social
- **Database Backups**: MariaDB (monolith), PostgreSQL (tty-ruinous-social)

### Monitoring & Observability
- **Grafana Alloy** for logs and metrics: monolith, obelisk, pilaster, tty-ruinous-social
- **Prometheus Node Exporter**: obelisk

### Container Orchestration
- **Docker** on: monolith, obelisk, pilaster, tty-ruinous-social
- **MicroVM** on: obelisk (hosts 2 VMs)

### Network Services
- **NFS**: monolith, obelisk, pilaster
- **Printing (CUPS)**: monolith, obelisk, framework
- **Cloudflared Tunnels**: monolith

## Platform Summary

| Host | Type | Platform | CPU | RAM | Primary Role |
|------|------|----------|-----|-----|--------------|
| monolith | Server | NixOS | i9-13900H | 96 GB | Infrastructure hub |
| obelisk | Server | NixOS | i9-14900KF | 64 GB | GPU compute + VMs |
| pilaster | Server | NixOS | i9-13900H | 96 GB | Containers |
| void | Thin Client | NixOS | GX-424CC | 4 GB | HA master |
| gap | Thin Client | NixOS | GX-424CC | 4 GB | HA backup |
| tty-ruinous-social | VPS | NixOS | 4 cores | 8 GB | Cloud services |
| framework | Laptop | NixOS | Ultra 5 125H | 32 GB | Desktop/dev |
| ruinous-tty | MicroVM | NixOS | 2 cores | 2 GB | Dev (jmeskill) |
| messy-tty | MicroVM | NixOS | 2 cores | 2 GB | Dev (messy) |
| jbookpro | MacBook Pro | macOS | M4 | 32 GB | Development |
| jmacmini | Mac mini | macOS | M2 Pro | 16 GB | Development |
| studio | iMac Pro | macOS | Xeon W | 32 GB | Development |
