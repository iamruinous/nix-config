# 🖥️ iamruinous nix-config

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
├── .claude/              # oh-my-opencode agents and commands
├── .opencode/            # oh-my-opencode project configuration
└── justfile              # Command runner recipes (run `just` to see all)
```

## AI Agent Workflow

This repository uses **[OpenCode](https://opencode.ai)** with **[oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)** as the primary AI agent interface, with **Sisyphus** (Claude Opus 4.5) as the orchestrator.

### Quick Start

```bash
# Start OpenCode with Sisyphus orchestration
opencode

# Magic word for maximum performance
# Include "ultrawork" or "ulw" in your prompt
```

### Agent System

| Type | Agents | Purpose |
|------|--------|---------|
| **Built-in** | oracle, librarian, explore, frontend-ui-ux-engineer, document-writer | oh-my-opencode defaults |
| **Project** | agenix, cfnix, containnix, nix-packager | Custom agents in `.claude/agents/` |

### Project Specialists

| Agent | Responsibilities |
|-------|------------------|
| **`agenix`** | Secrets management (`.age` files), rekeying, encryption |
| **`cfnix`** | Cloudflare DNS records & Tunnel configuration |
| **`containnix`** | Docker/OCI container deployment, networking, proxy setup |
| **`nix-packager`** | Creating and converting Nix packages |

### Common Recipes

- **Create Database**: `/create-db-<host>` (e.g., `/create-db-monolith`)
- **Create Pi Host**: `/create-pi-host`

### Context Files

| File | Purpose |
|------|---------|
| **AGENTS.md** | Primary context beacon for OpenCode |
| **.claude/agents/** | Custom agent definitions |
| **.claude/commands/** | Slash commands |

For complete documentation, see **[AGENTS.md](AGENTS.md)**.

## Hosts

This configuration manages **24 hosts** across multiple platforms:

- **14 NixOS Servers** (Physical infrastructure, Raspberry Pi cluster)
- **2 NixOS Thin Clients** (High Availability pair)
- **1 Cloud VPS** (Remote services)
- **2 NixOS Workstations** (Desktop & Laptop)
- **2 NixOS MicroVMs** (Development environments)
- **3 macOS Systems** (Development workstations)

For detailed information about each host including hardware specifications, key features, and purposes, see **[hosts/README.md](hosts/README.md)**.

## Custom Packages

This repository includes custom Nix packages for specialized functionality:

- **agenix-helper** - Helper utility for managing passphrase-protected age identities with 1Password integration
- **backup-docker-mariadb** - Automated MariaDB backup with integrated NixOS module and systemd timer
- **backup-docker-postgres** - Automated PostgreSQL backup with integrated NixOS module and systemd timer
- **docker-mcp-gateway** - Docker CLI plugin for Model Context Protocol integration
- **forgejo-shell** - SSH shell wrapper for Forgejo Docker container
- **messy-restricted-shell** - Restricted shell with whitelisted commands
- **nelko-pl70ebt** - CUPS driver for Nelko PL70e-BT label printer
- **pinentry-1password** - Pinentry-compatible program using 1Password CLI for passphrase retrieval
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
- **[Harmonia](https://github.com/nix-community/harmonia)** - Private Nix binary cache

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

Or use the justfile helper:

```sh
just darwin-rebuild
```

This automatically uses the current hostname.

### Remote Deployment

To deploy a configuration to a remote NixOS host:

```sh
just remote-rebuild <hostname>
```

This will connect to `<hostname>.meskill.farm` and apply the configuration.

### Updating Flake Inputs

To update all Nix flake inputs (nixpkgs, home-manager, etc.):

```sh
nix flake update
```

Or use the justfile:

```sh
just update-flake
```

### Development Shells

Enter a development shell with project-specific tools:

```sh
nix develop                    # Default development shell
nix develop .#pdftools         # PDF manipulation tools
nix develop .#python313        # Python 3.13 environment
nix develop .#n8n-node-dev     # n8n custom node development
```

For detailed information about available shells, direnv integration, and creating custom shells, see **[devshells/README.md](devshells/README.md)**.

### Bootstrap macOS

To bootstrap a fresh macOS system with Nix and nix-darwin:

```sh
just bootstrap-mac
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

### 1Password Integration

If you use 1Password CLI, you can store your age identity passphrase in 1Password and have `agenix-helper` retrieve it automatically:

```sh
# Set up 1Password secret reference
export OP_PIN_ITEM="op://Private/age-identity/passphrase"

# Unlock without typing passphrase (retrieved from 1Password)
agenix-helper unlock
```

This requires:
- 1Password CLI (`op`) installed and authenticated
- `pinentry-1password` package installed
- `OP_PIN_ITEM` environment variable set to your 1Password secret reference

See the [agenix-helper package documentation](packages/agenix-helper/README.md) and [pinentry-1password documentation](packages/pinentry-1password/README.md) for details.

### Traditional Workflow

To edit secrets directly (prompts for passphrase each time):

```sh
agenix -e secrets/<secret-name>.age
```

Secrets are automatically decrypted on the target system and available to services that reference them.

## Private Binary Cache

A private [Harmonia](https://github.com/nix-community/harmonia) binary cache is available for hosts on the Tailscale network at `cache.nix.meskill.farm`.

### Configuring Clients

Add the following to your NixOS configuration to use the private cache:

```nix
nix.settings = {
  substituters = [ "https://cache.nix.meskill.farm" ];
  trusted-public-keys = [ "cache.nix.meskill.farm-1:9Ih1t1q9biWeHg28x+qunDj42JkaGfLd95YD2ltEAAw=" ];
};
```

Or for flake-based configurations in `flake.nix`:

```nix
nixConfig = {
  extra-substituters = [ "https://cache.nix.meskill.farm" ];
  extra-trusted-public-keys = [ "cache.nix.meskill.farm-1:9Ih1t1q9biWeHg28x+qunDj42JkaGfLd95YD2ltEAAw=" ];
};
```

### Access Requirements

- Host must be on the Tailscale network (100.0.0.0/8) or local network (10.55.0.0/16)
- No authentication required for authorized networks
- External requests receive HTTP 403

### Verifying Cache Access

```sh
# Test cache connectivity
curl -I https://cache.nix.meskill.farm/nix-cache-info

# Expected response: HTTP 200 with cache metadata
```

