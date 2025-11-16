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
├── hosts/                 # Individual host configurations (14 hosts)
├── modules/               # Reusable NixOS, Darwin, and home-manager modules
│   ├── nixos/            # NixOS-specific modules
│   │   ├── default/      # Common NixOS modules (docker, tailscale, backups, etc.)
│   │   ├── desktop/      # Desktop environment modules (fonts, flatpak, steam, etc.)
│   │   └── common/       # Shared configurations
│   ├── darwin/           # macOS-specific modules
│   └── home/             # home-manager modules (fish, git, wezterm, tmux, etc.)
├── packages/             # Custom Nix packages
├── users/                # User configurations (jmeskill, git, messy)
├── devshells/            # Development shell environments
├── lib/                  # Custom Nix library functions
├── secrets/              # Encrypted secrets managed with agenix
├── files/                # Static configuration files
└── Makefile              # Helper commands for common operations
```

## Hosts

### NixOS Systems (9)

- **framework** - Framework laptop with Intel Core Ultra, KDE Plasma 6, Lanzaboote secure boot
- **monolith** - Primary server with Docker containers, NFS shares, Restic backups, Tailscale
- **obelisk** - Server
- **pilaster** - Server with Tailscale
- **gap** - Workstation/server
- **void** - Workstation/server
- **ruinous-tty** - TTY-only system
- **messy-tty** - TTY-only system with restricted shell
- **tty-ruinous-social** - TTY-only system

### macOS Systems (3)

- **jmacmini** - Mac mini with nix-darwin
- **jbookpro** - MacBook Pro with nix-darwin
- **studio** - Mac Studio with nix-darwin

## Custom Packages

Custom packages are defined in `packages/` and include:

- **forgejo-shell** - Custom shell for Forgejo Git hosting service
- **messy-restricted-shell** - Restricted shell environment for the "messy" user account
- **nelko-pl70ebt** - Thermal label printer driver/utility

## Key Features

### Infrastructure

- **Blueprint** - Structured flake organization that maps directory structure to outputs
- **Home Manager** - Declarative dotfile and user environment management
- **Agenix** - Encrypted secrets management with age
- **Disko** - Declarative disk partitioning and formatting
- **System Manager** - Unified system configuration across NixOS and Darwin

### Desktop Environments

Multiple desktop environment modules available:
- KDE Plasma 6
- Hyprland (Wayland compositor)
- GNOME
- LXQT
- XFCE

### Development

- **Development Shells** - Pre-configured environments (default, pdftools, python313)
- **Devenv** - Integrated development environment support
- **Rust Toolchain** - Fenix for reproducible Rust builds
- **Docker** - Container support on multiple hosts

### Security & Services

- **Lanzaboote** - Secure boot with UEFI
- **Tailscale** - Mesh VPN networking
- **Restic** - Automated backups to remote storage
- **Caddy** - Reverse proxy and web server
- **Cloudflared** - Cloudflare tunnel support
- **Alloy** - Observability and monitoring

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

Secrets are encrypted using [agenix](https://github.com/ryantm/agenix) and stored in `secrets/`. To edit secrets:

```sh
agenix -e secrets/<secret-name>.age
```

Secrets are automatically decrypted on the target system and available to services that reference them.

## Using Devshells with direnv

This repository uses [direnv](https://direnv.net/) to automatically load development environments when you enter a project directory. The `.envrc` file tells direnv which Nix devshell to load.

### Current .envrc Configuration

The root `.envrc` file loads the default devshell:

```bash
#!/usr/bin/env bash
# Used by https://direnv.net
source_up

# Automatically reload when this file changes
watch_file devshells/default.nix

# Load `nix develop`
use flake

# Extend the environment with per-user overrides
source_env_if_exists .envrc.local

export SEATBELT_PROFILE="permissive-open-with-tmp"
export GEMINI_SANDBOX=true
```

### Creating a New .envrc for a Specific Devshell

To use a different devshell (e.g., `pdftools` or `python313`) in a project directory:

1. **Create an `.envrc` file** in your project directory:

```bash
#!/usr/bin/env bash
# Load a specific devshell from the nix-config flake
use flake ~/Projects/github/iamruinous/nix-config#pdftools
```

2. **Allow direnv** to load the configuration:

```bash
direnv allow
```

3. **The environment will automatically load** when you `cd` into the directory

### Available Devshells

- **default** - `use flake` or `use flake .#default`
- **pdftools** - `use flake .#pdftools` - PDF manipulation tools (ghostscript, poppler-utils, etc.)
- **python313** - `use flake .#python313` - Python 3.13 environment

### Creating a New Devshell

1. **Create a new file** in `devshells/` (e.g., `devshells/nodejs.nix`):

```nix
{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    nodejs_22
    nodePackages.npm
    nodePackages.pnpm
    nodePackages.typescript
  ];
}
```

2. **The Blueprint system** automatically discovers and exposes it as a flake output

3. **Use it in an `.envrc`**:

```bash
use flake ~/Projects/github/iamruinous/nix-config#nodejs
```

### .envrc Best Practices

- **watch_file** - Automatically reload when specific files change:
  ```bash
  watch_file devshells/pdftools.nix
  ```

- **source_up** - Inherit environment from parent directories

- **source_env_if_exists** - Load local overrides without tracking them in git:
  ```bash
  source_env_if_exists .envrc.local
  ```

- **Environment variables** - Export project-specific variables:
  ```bash
  export DATABASE_URL="postgresql://localhost/mydb"
  ```
