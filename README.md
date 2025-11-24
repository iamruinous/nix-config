# iamruinous nix-config

[![Build Status](https://github.com/iamruinous/nix-config/actions/workflows/flake-check.yml/badge.svg)](https://github.com/iamruinous/nix-config/actions/workflows/flake-check.yml)

**Connect:** [X](https://x.com/iamruinous) • [Instagram](https://instagram.com/iamruinous) • [Bluesky](https://bsky.app/profile/iamruinous.com) • [Mastodon](https://ruinous.social/@iamruinous)

Blueprint-driven NixOS and nix-darwin configurations with declarative system management for multiple hosts.

## Overview

This repository uses [Nix Flakes](https://nixos.org/) to manage system configurations across NixOS and macOS systems. It leverages [Blueprint](https://github.com/numtide/blueprint) for structured organization, making it easy to share configurations between hosts while maintaining host-specific customizations.

## Repository Structure

```
.
├── flake.nix              # Main flake configuration with inputs and outputs
├── hosts/                 # Individual host configurations (see hosts/README.md)
├── modules/               # Reusable NixOS, Darwin, and home-manager modules
│   ├── nixos/            # NixOS-specific modules
│   │   ├── default/      # Common NixOS modules (docker, tailscale, backups, etc.)
│   │   ├── desktop/      # Desktop environment modules (fonts, flatpak, steam, etc.)
│   │   └── common/       # Shared configurations
│   ├── darwin/           # macOS-specific modules
│   └── home/             # home-manager modules (fish, git, wezterm, tmux, etc.)
├── packages/             # Custom Nix packages (see packages/README.md)
├── users/                # User configurations (jmeskill, git, messy)
├── devshells/            # Development shell environments (see devshells/README.md)
├── lib/                  # Custom Nix library functions
├── secrets/              # Encrypted secrets managed with agenix
├── files/                # Static configuration files
└── Makefile              # Helper commands for common operations
```

## Hosts

This configuration manages 12 hosts across multiple platforms:
- 6 NixOS servers (physical and cloud)
- 3 NixOS MicroVMs (development environments)
- 3 macOS systems (development workstations)

For detailed information about each host including hardware specifications, key features, and purposes, see **[hosts/README.md](hosts/README.md)**.

## Custom Packages

This repository includes custom Nix packages for specialized functionality:

- **agenix-helper** - Helper utility for managing passphrase-protected age identities
- **docker-mcp-gateway** - Docker CLI plugin for Model Context Protocol integration
- **forgejo-shell** - SSH shell wrapper for Forgejo Docker container
- **messy-restricted-shell** - Restricted shell with whitelisted commands
- **nelko-pl70ebt** - CUPS driver for Nelko PL70e-BT label printer
- **ssh-agent-check** - Fast, cached SSH agent availability checker

For detailed information about each package including usage examples and dependencies, see **[packages/README.md](packages/README.md)**.

## Key Features

### Infrastructure

- **[Blueprint](https://github.com/numtide/blueprint)** - Structured flake organization that maps directory structure to outputs
- **[Home Manager](https://github.com/nix-community/home-manager)** - Declarative dotfile and user environment management
- **[Agenix](https://github.com/ryantm/agenix)** - Encrypted secrets management with age
- **[Disko](https://github.com/nix-community/disko)** - Declarative disk partitioning and formatting
- **[System Manager](https://github.com/numtide/system-manager)** - Unified system configuration across NixOS and Darwin

### Desktop Environments

Multiple desktop environment modules available:
- KDE Plasma 6
- Hyprland (Wayland compositor)
- GNOME
- LXQT
- XFCE

### Development

- **Development Shells** - Pre-configured environments (see [devshells/README.md](devshells/README.md))
- **[Devenv](https://devenv.sh)** - Integrated development environment support
- **[Fenix](https://github.com/nix-community/fenix)** - Rust toolchain for reproducible Rust builds
- **Docker** - Container support on multiple hosts

### Security & Services

- **[Lanzaboote](https://github.com/nix-community/lanzaboote)** - Secure boot with UEFI
- **[Tailscale](https://tailscale.com)** - Mesh VPN networking
- **[Restic](https://restic.net)** - Automated backups to remote storage
- **[Caddy](https://caddyserver.com)** - Reverse proxy and web server
- **[Cloudflared](https://github.com/cloudflare/cloudflared)** - Cloudflare tunnel support
- **[Grafana Alloy](https://grafana.com/docs/alloy)** - Observability and monitoring

### Home Manager Modules

Comprehensive user environment configurations for:
- **Shell**: fish, starship prompt, tmux
- **Terminal**: wezterm, alacritty
- **Development**: git, neovim, zed-editor, go
- **CLI Tools**: bat, eza, fzf, btop, bottom
- **Productivity**: todoist, vdirsyncer, khal
- **Security**: age, gpg, keychain, ssh

## Common Activities

### Building and Applying NixOS Configuration

To build and apply the NixOS configuration for a specific host (e.g., `framework`):

```sh
nixos-rebuild switch --flake .#framework
```

Replace `framework` with the name of your host.

### Building and Applying nix-darwin Configuration

To build and apply the nix-darwin configuration for a specific macOS host (e.g., `jmacmini`):

```sh
darwin-rebuild switch --flake .#jmacmini
```

Or use the Makefile helper:

```sh
make darwin-rebuild
```

This automatically uses the current hostname.

### Remote Deployment

To deploy a configuration to a remote NixOS host:

```sh
make remote-rebuild remotehost=<hostname>
```

This will connect to `<hostname>.manage.farmhouse.meskill.network` and apply the configuration.

### Updating Flake Inputs

To update all Nix flake inputs (nixpkgs, home-manager, etc.):

```sh
nix flake update
```

Or use the Makefile:

```sh
make update-flake
```

### Development Shells

Enter a development shell with project-specific tools:

```sh
nix develop                    # Default development shell
nix develop .#pdftools         # PDF manipulation tools
nix develop .#python313        # Python 3.13 environment
```

For detailed information about available shells, direnv integration, and creating custom shells, see **[devshells/README.md](devshells/README.md)**.

### Bootstrap macOS

To bootstrap a fresh macOS system with Nix and nix-darwin:

```sh
make bootstrap-mac
```

This will:
1. Install Nix with the daemon
2. Install nix-darwin
3. Apply the configuration for the current hostname

## Adding a New Host

1. Create a new directory under `hosts/` with your hostname
2. Add a `configuration.nix` (NixOS) or `darwin-configuration.nix` (macOS)
3. For NixOS, optionally run `nixos-generate-config` to create `hardware-configuration.nix`
4. Import the appropriate modules from `modules/nixos` or `modules/darwin`
5. Add user-specific home-manager configurations in `hosts/<hostname>/users/`
6. Build and apply: `nixos-rebuild switch --flake .#<hostname>`

## Secrets Management

Secrets are encrypted using [agenix](https://github.com/ryantm/agenix) and stored in `secrets/`.

### Quick Workflow with agenix-helper

For a streamlined experience when working with multiple secrets:

```sh
# Unlock once per session (enter passphrase once)
agenix-helper unlock

# Edit secrets without repeated passphrase prompts
agenix edit secrets/<secret-name>.age
agenix rekey -a

# Lock when done
agenix-helper lock
```

See the [agenix-helper package documentation](packages/agenix-helper/README.md) for details.

### Traditional Workflow

To edit secrets directly (prompts for passphrase each time):

```sh
agenix -e secrets/<secret-name>.age
```

Secrets are automatically decrypted on the target system and available to services that reference them.

