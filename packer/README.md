# Packer Templates

Automated macOS VM image building for Tart.

## Quick Start

```bash
tart pull ghcr.io/cirruslabs/macos-sequoia-base:latest
packer init macos-nix-base.pkr.hcl
packer build macos-nix-base.pkr.hcl
```

## Templates

| Template | Output | Description |
|----------|--------|-------------|
| `macos-nix-base.pkr.hcl` | `macos-sequoia-nix` | macOS with Nix pre-installed |

## Documentation

See [docs/TART-IMAGE-BUILDING.md](../docs/TART-IMAGE-BUILDING.md) for full documentation.
