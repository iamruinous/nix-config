# Tart VM Image Building

This guide covers creating customized macOS VM images with Nix pre-installed using Packer and Tart.

## Overview

| Component | Purpose |
|-----------|---------|
| **Tart** | macOS/Linux virtualization on Apple Silicon |
| **Packer** | Automated VM image building |
| **Cirrus Labs Base Images** | Pre-configured macOS images (SSH enabled, Homebrew installed) |
| **Determinate Nix Installer** | Reliable unattended Nix installation |

### Key Limitation

**Tart does NOT support Docker-style layering.** Each image is a single OCI artifact. When you modify an image, it creates a full copy—not a delta layer.

## Prerequisites

```bash
brew install cirruslabs/cli/tart
brew install packer
packer plugins install github.com/cirruslabs/tart
```

## Quick Start

### 1. Pull Base Image

```bash
tart pull ghcr.io/cirruslabs/macos-sequoia-base:latest
```

Available base images:
- `macos-ventura-base` - macOS 13
- `macos-sonoma-base` - macOS 14
- `macos-sequoia-base` - macOS 15
- `macos-tahoe-base` - macOS 26 (Tahoe)

### 2. Build Nix-Enabled Image

```bash
cd packer
packer init macos-nix-base.pkr.hcl
packer build macos-nix-base.pkr.hcl
```

This creates a VM named `macos-sequoia-nix` with Nix installed.

### 3. Push to Registry (Optional)

```bash
tart push macos-sequoia-nix ghcr.io/iamruinous/macos-sequoia-nix:latest
```

## Build Variants

### Nix-Only Image (Default)

Creates a base image with just Nix installed:

```bash
packer build macos-nix-base.pkr.hcl
```

### With nix-darwin Pre-configured

Creates an image with nix-darwin bootstrapped from your flake:

```bash
packer build \
  -var "install_nix_darwin=true" \
  -var "nix_config_repo=github:iamruinous/nix-config" \
  -var "nix_config_host=clawdbot-vm" \
  macos-nix-base.pkr.hcl
```

### Different macOS Version

```bash
tart pull ghcr.io/cirruslabs/macos-tahoe-base:latest

packer build \
  -var "base_image=macos-tahoe-base" \
  -var "vm_name=macos-tahoe-nix" \
  macos-nix-base.pkr.hcl
```

### Custom Resources

```bash
packer build \
  -var "cpu_count=8" \
  -var "memory_gb=16" \
  -var "disk_size_gb=100" \
  macos-nix-base.pkr.hcl
```

## Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `base_image` | `macos-sequoia-base` | Local VM name (must be pulled first) |
| `vm_name` | `macos-sequoia-nix` | Output VM name |
| `cpu_count` | `4` | Number of CPU cores |
| `memory_gb` | `8` | Memory in GB |
| `disk_size_gb` | `80` | Disk size in GB |
| `ssh_username` | `admin` | SSH user (Cirrus images use `admin`) |
| `ssh_password` | `admin` | SSH password |
| `install_nix_darwin` | `false` | Bootstrap nix-darwin |
| `nix_config_repo` | `` | Flake repo (e.g., `github:user/repo`) |
| `nix_config_host` | `` | Hostname in flake |

## Manual Workflow (Alternative)

If you prefer not to use Packer:

```bash
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest my-custom-vm

tart run my-custom-vm

ssh admin@$(tart ip my-custom-vm)

curl -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

exit

tart stop my-custom-vm

tart push my-custom-vm ghcr.io/iamruinous/macos-sequoia-nix:latest
```

## Deployment

### Using the Built Image

```bash
tart clone macos-sequoia-nix clawdbot
tart run clawdbot
```

### With Tart-VM Module

The built image works with the `ruinous.tart-vm` nix-darwin module:

```nix
ruinous.tart-vm = {
  enable = true;
  vms.clawdbot = {
    enable = true;
    cpu = 4;
    memory = 8192;
    autostart = true;
    headless = true;
    sharedDirs = [ "/Users/jmeskill/shared/clawdbot" ];
  };
};
```

## What Can't Be Automated

| Item | Reason |
|------|--------|
| **Apple ID sign-in** | Requires GUI interaction |
| **iMessage activation** | Requires Apple ID + SMS verification |
| **Keychain setup** | Some operations need unlocked keychain |

**Strategy:** Build a "Nix-ready" base image. Apple ID/iMessage setup remains manual post-deployment.

## Troubleshooting

### SSH Connection Timeout

The VM may take several minutes to boot. Increase timeout:

```hcl
source "tart-cli" "macos-nix" {
  ssh_timeout = "15m"
}
```

### Nix Installation Fails

Check the VM has internet access. Tart uses NAT by default.

```bash
tart run --no-graphics my-vm &
ssh admin@$(tart ip my-vm) "curl -I https://nixos.org"
```

### Disk Space Issues

Base images are ~50GB. Ensure `disk_size_gb` is sufficient for Nix store:

```bash
packer build -var "disk_size_gb=100" macos-nix-base.pkr.hcl
```

### nix-darwin Interactive Prompt

The bootstrap script moves `/etc/nix/nix.conf` to avoid this. If you see a prompt, the script may have failed:

```bash
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.bak
nix run nix-darwin -- switch --flake .#hostname
```

## Registry Options

### GitHub Container Registry (GHCR)

```bash
echo $GITHUB_TOKEN | tart login ghcr.io -u USERNAME --password-stdin
tart push my-vm ghcr.io/iamruinous/my-vm:latest
```

### Private Registry

Tart supports any OCI-compatible registry:

```bash
tart push my-vm registry.example.com/my-vm:latest
```

## CI/CD Integration

### GitHub Actions

```yaml
jobs:
  build-image:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      
      - name: Install tools
        run: |
          brew install cirruslabs/cli/tart packer
          packer plugins install github.com/cirruslabs/tart
      
      - name: Pull base image
        run: tart pull ghcr.io/cirruslabs/macos-sequoia-base:latest
      
      - name: Build image
        run: |
          cd packer
          packer build macos-nix-base.pkr.hcl
      
      - name: Push image
        run: |
          echo "${{ secrets.GITHUB_TOKEN }}" | tart login ghcr.io -u ${{ github.actor }} --password-stdin
          tart push macos-sequoia-nix ghcr.io/${{ github.repository_owner }}/macos-sequoia-nix:latest
```

## Related Documentation

- [Tart Documentation](https://tart.run)
- [Packer Tart Plugin](https://developer.hashicorp.com/packer/integrations/cirruslabs/tart)
- [Cirrus Labs Image Templates](https://github.com/cirruslabs/macos-image-templates)
- [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer)
- [Tart-VM Module](../modules/darwin/tart-vm/default.nix) - nix-darwin Tart integration
