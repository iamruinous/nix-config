# Coding & Operational Standards

## Code Style
*   **Nix:** Use `alejandra` for formatting.
*   **Shell:** Use `set -euo pipefail`. Use `writeShellApplication` or `pkgs.writeShellScriptBin` in Nix.
*   **Imports:** Group standard imports, then project modules, then local files.

## Git Workflow
*   **Branching:** Use `feat/`, `fix/`, `docs/`, `chore/` prefixes.
*   **Commits:**
    *   Use Conventional Commits (`feat: description`).
    *   **MUST** be GPG signed.
*   **PRs:** Create draft PRs early. Update status as you go.

## Testing Strategy
1.  **Format:** `alejandra .`
2.  **Dry Build:** `make remote-dry-build remotehost=<target>` (Critical for NixOS changes).
3.  **Local Build:** `nix build .#<package>` (For packages).
4.  **Check:** `make check` (CI validation).

## Security
*   **Secrets:** All secrets must be encrypted with `agenix`.
*   **Sandbox:** Most build steps run in sandbox. Agent tools like `agenix` or `cfcli` may require disabling sandbox (`dangerouslyDisableSandbox: true`).

## Package Guidelines
*   **Structure:** Follow the standard `stdenv.mkDerivation` or language-specific builder patterns.
*   **Meta:** Always include `description`, `license`, `maintainers`.
*   **Pinning:** Pin dependencies and sources (hashes).

## Container Guidelines
*   **Networks:**
    *   `servicenet`: Inter-container & Caddy access.
    *   `datanet`: Internal databases (no external access).
    *   `proxynet`: Host port binding (use sparingly).
*   **Images:** Pin tags (no `:latest`).
*   **Env:** Use encrypted `.env.age` files.
