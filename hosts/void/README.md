# void

NixOS server configured for high availability with VRRP (Virtual Router Redundancy Protocol).

## Hardware

- **Model**: Dell Wyse 5060 Thin Client
- **Platform**: x86_64-linux
- **CPU**: AMD GX-424CC 2.4GHz (4 cores, KVM support)
- **Memory**: 4 GB RAM
- **Storage**: 8 GB Flash, Btrfs filesystem managed by Disko
- **Network**: Single ethernet interface (enp4s0)
- **IP Address**: 10.55.10.36/24

## Key Features

### High Availability
- Keepalived VRRP for failover
- MASTER role in VRRP instance VIP_35
- Virtual IP: 10.55.10.34/24
- Virtual Router ID: 35
- Priority: 44
- VMAC (Virtual MAC) enabled

### Network Configuration
- Static IP configuration via systemd-networkd
- Gateway: 10.55.10.1
- DNS: 10.55.10.35

## Purpose

High availability master node working in conjunction with the `gap` host (which is the BACKUP). Normally owns the virtual IP 10.55.10.34 and services traffic. If this node fails, the backup node automatically takes over the virtual IP using VRRP to ensure service continuity.
