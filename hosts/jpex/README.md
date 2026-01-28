# jpex

Mac mini M4 running nix-darwin with Tart VM support for clawdbot deployment.

## Hardware

- **Model**: Apple Mac mini (M4, 2024)
- **Platform**: aarch64-darwin (Apple Silicon)
- **Chip**: Apple M4 with 10-Core CPU, 10-Core GPU
- **Memory**: 24 GB unified memory
- **Storage**: 512 GB SSD
- **OS**: macOS Tahoe (26.x)

## Key Features

### Tart Virtual Machines
- Tart VM module enabled for macOS-on-macOS virtualization
- Uses Apple Virtualization.framework for native ARM64 VMs
- Bridged networking (en0) for DHCP from router

### Configured VMs

| VM | CPU | Memory | Purpose |
|----|-----|--------|---------|
| clawdbot | 4 | 8 GB | Claude Code assistant with iMessage integration |

### Budgey Session Extractors
- OpenCode, Claude, Codex, Gemini extractors
- Hourly extraction to shared git archive
- Chassis handles enrichment and ingestion

### Development Environment
- Developer tools and environment configured
- nix-darwin for declarative macOS configuration

### User Configuration
- Primary user: jmeskill
- Home directory: /Users/jmeskill

## VM Management

```bash
# List VMs
tart list

# Start clawdbot VM (with GUI)
tart run clawdbot

# Start with bridged networking (DHCP from router)
tart run --net-bridged=en0 clawdbot

# Get VM IP address
tart ip clawdbot

# SSH into VM (default credentials: admin/admin)
ssh admin@$(tart ip clawdbot)
```

## Purpose

Primary host for running clawdbot in a Tart VM with iMessage integration. The VM provides isolation and macOS-specific features (iMessage, GUI) while the host manages the VM lifecycle.

## Related

- Issue #314: Deploy clawdbot to Tart VM on jpex
- [nix-clawdbot](https://github.com/clawdbot/nix-clawdbot) - Claude Code integration for Nix
- [Tart](https://tart.run/) - macOS VM management
