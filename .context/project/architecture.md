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

### Shell Script Packages (Preferred Pattern)
When creating packages that are primarily shell scripts, **prefer external `.sh` files with `substitute`** over inline scripts in `writeShellApplication`. This pattern:
- Makes scripts easier to edit and debug (no escaping issues)
- Enables syntax highlighting and linting in editors
- Allows testing scripts independently
- Keeps Nix derivations clean and focused on build logic

**Standard Pattern:**
```
packages/<name>/
├── default.nix      # Uses stdenv.mkDerivation + substitute
├── <name>.sh        # The actual shell script
└── README.md        # Documentation
```

**Shell Script Template (`<name>.sh`):**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Use @placeholder@ for executable paths that Nix will substitute
@docker@/bin/docker ps
@ssh@/bin/ssh user@host
```

**Derivation Template (`default.nix`):**
```nix
{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "<name>";
  version = "1.0.0";
  dontUnpack = true;

  propagatedBuildInputs = with pkgs; [
    # Runtime dependencies available in PATH
    docker
    openssh
  ];

  passthru.shellPath = "/bin/<name>";
  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin
    substitute ${./<name>.sh} $out/bin/<name> \
      --replace '@docker@' '${pkgs.docker}' \
      --replace '@ssh@' '${pkgs.openssh}'
    chmod +x $out/bin/<name>
  '';

  installPhase = ''
    true
  '';

  meta = with pkgs.lib; {
    description = "...";
    license = licenses.mit;
    mainProgram = "<name>";
    platforms = platforms.unix;
  };
}
```

**Key Points:**
- Use `@placeholder@` syntax for paths that need substitution
- Always use full paths in scripts (`@pkg@/bin/command`) for reproducibility
- `propagatedBuildInputs` ensures deps are available at runtime
- Test with `nix build .#<package-name>` then run `./result/bin/<name>`

## AI Agent Workflow
For operational protocols, see **[Context Index](../index.md)** and **[Global Protocols](../global/protocols.md)**.

*   **Hub-and-Spoke:** Defined in `global/protocols.md`.
*   **Planning:** Mandatory phase before execution.
*   **Safety:** Verify builds before committing.