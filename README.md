# iamruinous dotfiles

My personal dotfiles, managed with [chezmoi](https://www.chezmoi.io/) and [Nix](https://nixos.org/).

## Installation

### Prerequisites

- [Git](https://git-scm.com/)
- [chezmoi](https://www.chezmoi.io/install/)

### Quick Start

```sh
chezmoi init iamruinous
```

This command will clone the repository. To see what changes will be made to your home directory, you can run:

```sh
chezmoi diff
```

To apply the changes, run:
```sh
chezmoi apply
```

## Nix Configuration

This repository uses [Nix](https://nixos.org/) to manage system configurations for various hosts (NixOS and macOS with nix-darwin). The configurations are defined in the `hosts/` directory.

### Blueprint

The `blueprint` system is used to define common configurations that can be applied across different hosts. This helps in maintaining consistency and reducing duplication.

### Common Activities

#### Building and Applying NixOS Configuration

To build and apply the NixOS configuration for a specific host (e.g., `framework`), navigate to the `nix-config` directory and run:

```sh
nixos-rebuild switch --flake .#framework
```

Replace `framework` with the name of your host.

#### Building and Applying nix-darwin Configuration

To build and apply the nix-darwin configuration for a specific macOS host (e.g., `jbookair`), navigate to the `nix-config` directory and run:

```sh
darwin-rebuild switch --flake .#jbookair
```

Replace `jbookair` with the name of your macOS host.

#### Updating Nix Flake Inputs

To update the Nix flake inputs (e.g., Nixpkgs, home-manager), run the following command from the `nix-config` directory:

```sh
nix flake update
```

#### Entering a Development Shell

To enter a development shell defined in `devshells/default.nix`, run:

```sh
nix develop
```

This will provide a shell environment with all the tools and dependencies specified in the devshell.
