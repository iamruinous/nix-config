# Project Context

## Overview
This is a NixOS configuration repository managing multiple NixOS and Darwin (macOS) machines. It uses the `blueprint` flake to map directory structure to flake outputs automatically.

## Directory Structure
*   `flake.nix`: Main entry point.
*   `hosts/`: Configuration for each machine (e.g., `hosts/monolith/`).
*   `modules/`: Reusable modules (`nixos`, `darwin`, `home`).
*   `packages/`: Custom packages (auto-discovered by blueprint).
*   `secrets/`: Encrypted secrets (Agenix).
*   `lib/`: Helper functions.
*   `users/`: User-specific configurations (Home Manager).
*   `devshells/`: Development shell definitions.
*   `.context/`: Unified AI agent context and instructions.

## Key Technologies
*   **NixOS / nix-darwin:** Operating systems.
*   **Blueprint:** Flake structure automation.
*   **Agenix:** Secrets management (encrypted `.age` files).
*   **Home Manager:** User configuration.
*   **Disko:** Disk partitioning.
*   **Docker / OCI:** Container orchestration (`virtualisation.oci-containers`).
*   **Cloudflare:** DNS and Tunnels (`cfnix` agent).
*   **Caddy:** Reverse proxy (configured via Caddyfile secrets).

## Building & Deploying
*   **NixOS Switch:** `nixos-rebuild switch --flake .#<hostname>`
*   **Darwin Switch:** `darwin-rebuild switch --flake .#<hostname>`
*   **Remote Build:** `make remote-rebuild remotehost=<hostname>`
*   **Dry Build:** `make remote-dry-build remotehost=<hostname>`
*   **Package Build:** `nix build .#<package-name>`

## Development Conventions
*   **Modularity:** Prefer creating reusable modules in `modules/` over ad-hoc config.
*   **Secrets:** **NEVER** commit unencrypted secrets. Use `agenix`.
*   **Formatting:** Nix code is formatted with `alejandra`.
*   **Branches:** Work on feature branches (`feat/`, `fix/`). Main is protected.
*   **Commits:** Signed (GPG) and conventional (`feat:`, `fix:`).

## AI Agent Workflow
*   **Hub-and-Spoke:** Agents share context via `.context/`.
*   **Planning:** Always plan complex changes (creating files, refactoring) before execution.
*   **Safety:** Explain destructive actions. Verify builds before committing.
