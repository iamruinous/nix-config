# Gemini CLI Context

This file provides context to the Gemini CLI agent to help it understand the structure and conventions of this NixOS configuration repository.

## Project Overview

This is a NixOS configuration repository that uses the `blueprint` flake to map the directory structure to flake outputs. It manages the configurations for multiple NixOS and Darwin (macOS) machines.

-   `flake.nix`: Main entry point.
-   `hosts/`: Main configuration for each machine.
-   `modules/`: Reusable NixOS/home-manager modules.
-   `packages/`: Custom packages.
-   `secrets/`: Encrypted secrets (Agenix).

## Specialized Capabilities & Instructions

Detailed instructions for specific domains are located in `.gemini/instructions/`. **Refer to these files when performing related tasks.**

- **Secrets Management**: [.gemini/instructions/agenix.md](.gemini/instructions/agenix.md)
  - Creating/editing secrets, handling `.age` files.
- **Container Deployment**: [.gemini/instructions/containnix.md](.gemini/instructions/containnix.md)
  - Adding Docker containers, configuring Caddy, networking.
- **Cloudflare Integration**: [.gemini/instructions/cfnix.md](.gemini/instructions/cfnix.md)
  - DNS records, Cloudflare Tunnels, SSL.
- **Package Development**: [.gemini/instructions/nix-packager.md](.gemini/instructions/nix-packager.md)
  - Creating new packages, converting scripts.

## Common Recipes

- **Create Database**: [.gemini/instructions/create-db.md](.gemini/instructions/create-db.md)
- **Create Pi Host**: [.gemini/instructions/create-pi-host.md](.gemini/instructions/create-pi-host.md)

## Development Conventions

-   **Modularity:** Reuse modules in `modules/`.
-   **Blueprint:** Adhere to the blueprint structure.
-   **Secrets:** NEVER commit unencrypted secrets. Use `agenix`.
-   **Build & Deploy:**
    -   `nixos-rebuild switch --flake .#<hostname>`
    -   `make remote-rebuild remotehost=<hostname>`

## Git Workflow

**⚠️ IMPORTANT: The main branch is protected.**

1.  **Feature Branches:** Always work on a branch (`feat/`, `fix/`).
2.  **Draft PRs:** Create draft PRs early.
3.  **Verification:** Verify builds before committing (`make remote-dry-build`).
4.  **Signing:** All commits must be GPG signed.

## Agent Guidelines (for Gemini)

1.  **Check Instructions:** Before starting a complex task (like adding a container), read the relevant instruction file in `.gemini/instructions/`.
2.  **Plan First:** Create a plan using the TodoWrite tool or just a mental list, and confirm with the user.
3.  **Safety:** Be careful with `run_shell_command`. Explain destructive actions.
4.  **Context:** Use `read_file` to understand the current state of files before editing.
