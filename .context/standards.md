# Coding & Operational Standards

## Code Style
*   **Nix:** Use `alejandra` for formatting.
*   **Shell:** Use `set -euo pipefail`. Use `writeShellApplication` or `pkgs.writeShellScriptBin` in Nix.
*   **Imports:** Group standard imports, then project modules, then local files.

## Git Workflow
For detailed guidelines, see **[.context/git-workflow.md](./git-workflow.md)**.

*   **Branching:**
    *   **Protected Main:** Direct commits to `main` are rejected.
    *   **Conventions:** Use `feat/`, `fix/`, `docs/`, `chore/` prefixes (e.g., `feat/add-auth`).
*   **Commits:**
    *   **Format:** Use Conventional Commits (`type(scope): description`).
    *   **Signing:** **MUST** be GPG signed. Always run `ssh-agent-check` before committing.
    *   **Frequency:** Commit progressively, don't wait for the end.
*   **Pull Requests:**
    *   Create **Draft PRs** immediately after the first commit.
    *   Maintain a task list in the PR description.
    *   Review is required before merge.

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
