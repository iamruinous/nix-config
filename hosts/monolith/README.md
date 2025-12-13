# monolith

Primary NixOS server for infrastructure services, containers, and network services.

## Hardware

- **Model**: Minisforum MS-01
- **Platform**: x86_64-linux
- **CPU**: Intel Core i9-13900H (14 cores: 6P+8E, 20 threads, up to 5.4 GHz, KVM support)
- **Memory**: 96 GB DDR5-5200 (dual channel SODIMM)
- **GPU**: Intel Iris Xe Graphics (up to 1.5 GHz)
- **Network**: 2x 10Gbps SFP+, 2x 2.5Gbps RJ45 (I226-LM/I226-V), 2x USB4 (40Gbps), VLAN support
- **Storage**: Disko-managed NVMe, 3x M.2 slots, U.2 support, PCIe 4.0 x16 slot
- **Special Hardware**: Google Gasket kernel module support

## Key Features

### Networking
- VLAN 2 (services network): 10.55.20.24/24
- systemd-networkd configuration
- nftables firewall
- Cloudflared tunnels
- Tailscale VPN with subnet routing (10.55.0.0/16)

### Virtualization & Containers
- Docker with btrfs storage driver
- nix-ld for running binary applications
- Container networks: servicenet, proxynet, datanet

### Containerized Services

**Infrastructure:**
- **Caddy**: Reverse proxy with Cloudflare DNS and HTTPS
- **MariaDB**: Relational database
- **PostgreSQL**: Relational database
- **Redis**: In-memory data store
- **OpenLDAP**: Directory service with phpLDAPadmin
- **Prometheus**: Metrics collection with Alert Manager
- **Grafana**: Dashboards and visualization
- **Loki**: Log aggregation

**Media & Entertainment:**
- **Plex ecosystem**: Sonarr, Radarr, Bazarr, Prowlarr, Jellyseerr
- **Calibre**: E-book management with Calibre-Web Automated
- **Kavita**: Comic/manga reader
- **Pinchflat**: YouTube archiver
- **ErsatzTV**: Live TV streaming
- **ROMM**: ROM manager

**Productivity:**
- **Paperless-ngx**: Document management with AI classification
- **n8n**: Workflow automation
- **Forgejo**: Git forge (SSH on port 2222)
- **TaskTrove**: Task management
- **Glance**: Dashboard

**Home Automation:**
- **Frigate**: NVR with object detection (Google Coral TPU)
- **Zigbee2MQTT**: Zigbee gateway
- **Mosquitto**: MQTT broker with MQTT Explorer

**Downloaders (via Gluetun VPN):**
- **Deluge**: BitTorrent client
- **SABnzbd**: Usenet downloader
- **FlareSolverr**: Cloudflare bypass
- **Autobrr**: Torrent automation

**Other:**
- **Adminer**: Database management
- **Apprise**: Notification service
- **ChangeDetection**: Website monitoring
- **Step-CA**: Private certificate authority
- **ACME-DNS**: DNS-01 challenge server

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
