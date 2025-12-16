# chassis

Framework Desktop workstation running NixOS with secure boot.

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
- Todoist sync integration
- Vdirsyncer calendar/contacts sync
- SSH remote forwarding enabled

### Hardware Support
- Framework Desktop-specific hardware module
- AMD microcode updates
- Redistributable firmware enabled

## Purpose

High-performance desktop workstation for development and productivity. Features dual-boot capability with Windows and comprehensive NixOS configuration with secure boot.
