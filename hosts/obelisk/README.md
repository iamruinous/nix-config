# obelisk

NixOS server with NVIDIA GPU for containers, virtualization, and compute workloads.

## Hardware

- **Model**: Alienware Aurora R16 Gaming PC
- **Platform**: x86_64-linux
- **CPU**: Intel 14th Gen i9-14900KF (24 cores, KVM support, nested virtualization enabled)
- **Memory**: 64 GB DDR5 5600MHz XMP
- **GPU**: NVIDIA GeForce RTX 4090 (stable driver, container toolkit enabled)
- **Storage**: 2TB NVMe SSD, ext4 root filesystem
- **Network**: Dual ethernet, VLAN 2 support
- **IP Address**: 10.55.20.22/24 (VLAN 2)

## Key Features

### Graphics & Compute
- NVIDIA GPU with proprietary driver
- NVIDIA Container Toolkit for GPU access in containers
- Modesetting and power management enabled
- Sleep/suspend disabled (always-on server)

### Virtualization
- libvirt for VM management
- Docker for containers
- MicroVM hosting capability
- Binary emulation for aarch64 systems

### Networking
- VLAN 2 (services network): 10.55.20.22/24
- systemd-networkd configuration
- nftables firewall
- Tailscale VPN with subnet routing (10.55.0.0/16)

### Containerized Services
- **Caddy**: Reverse proxy with Cloudflare DNS and HTTPS
- **Ollama**: LLM inference server (GPU-accelerated)
- **Open WebUI**: Web interface for Ollama

### Services
- **Printing**: CUPS with network printer discovery
- **NFS**: Network file storage
- **SSH**: Custom SSH configuration
- **Backup**: Restic backups to terranas
- **Monitoring**: Grafana Alloy for observability and journal logging
- **Metrics**: Prometheus Node Exporter

### Development
- Developer tools and environment
- Hyprland window manager (available but not enabled by default)

### Security & Management
- Plymouth boot splash
- Firmware updates via fwupd

## Purpose

GPU-accelerated server for compute workloads, container services, and virtualization. The NVIDIA GPU enables ML/AI workloads, video transcoding, and other GPU-accelerated tasks in containers. Also serves as a hypervisor for MicroVMs and provides monitoring/observability for the infrastructure.
