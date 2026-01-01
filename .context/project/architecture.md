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

## Development Standards
*   **Modularity:** Prefer creating reusable modules in `modules/` over ad-hoc config.
*   **Formatting:** Nix code is formatted with `alejandra`.
*   **Verification:** 
    *   `make remote-dry-build remotehost=<target>` (Critical for NixOS changes).
    *   `make check` (CI validation).
*   **Security:** 
    *   **NEVER** commit unencrypted secrets. Use `agenix`.
    *   Agent tools like `agenix` or `cfcli` may require `dangerouslyDisableSandbox: true`.

## Container Architecture
*   **Networks:**
    *   `servicenet`: Inter-container & Caddy access.
    *   `datanet`: Internal databases (no external access).
    *   `proxynet`: Host port binding (use sparingly).
*   **Images:** Pin tags (no `:latest`).
*   **Env:** Use encrypted `.env.age` files.

## Package Architecture
*   **Structure:** Follow the standard `stdenv.mkDerivation` or language-specific builder patterns.
*   **Meta:** Always include `description`, `license`, `maintainers`.
*   **Pinning:** Pin dependencies and sources (hashes).

## AI Agent Workflow
For operational protocols, see **[Context Index](../index.md)** and **[Global Protocols](../global/protocols.md)**.

*   **Hub-and-Spoke:** Defined in `global/protocols.md`.
*   **Planning:** Mandatory phase before execution.
*   **Safety:** Verify builds before committing.