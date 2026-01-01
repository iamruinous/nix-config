# Gemini CLI Context

## ⚠️ Primary Context Source
**STOP:** Before proceeding, read the files in the `.context/` directory. This is the **Single Source of Truth** for this project.

*   **Project Overview & Architecture:** `.context/project-context.md`
*   **Coding & Git Standards:** `.context/standards.md`
*   **Agent Capabilities & Recipes:** `.context/agents/` and `.context/recipes/`

## Project Overview
This is a NixOS configuration repository using `blueprint` for structure. It manages NixOS and Darwin hosts.

## AI Agent Workflow
1.  **Read Instructions:** Check `.context/` for relevant domain knowledge (e.g., `.context/agents/containnix.md` for Docker).
2.  **Plan First:** Create a plan and confirm with the user.
3.  **Safety:** Explain destructive actions. Use `read_file` to verify state.

## Specialized Instructions
Refer to `.context/agents/` for detailed instructions on:
*   **Secrets Management (`agenix`)**: `.context/agents/agenix.md`
*   **Containers (`containnix`)**: `.context/agents/containnix.md`
*   **Cloudflare (`cfnix`)**: `.context/agents/cfnix.md`
*   **Packaging (`nix-packager`)**: `.context/agents/nix-packager.md`

## Common Recipes
*   **Create Database:** `.context/recipes/create-db.md`
*   **Create Pi Host:** `.context/recipes/create-pi-host.md`

## Development Conventions
*   **Modularity:** Reuse modules in `modules/`.
*   **Secrets:** NEVER commit unencrypted secrets.
*   **Build & Deploy:**
    *   `nixos-rebuild switch --flake .#<hostname>`
    *   `make remote-rebuild remotehost=<hostname>`

## Git Workflow
*   **Feature Branches:** Always work on a branch (`feat/`, `fix/`).
*   **Verification:** Verify builds (`make remote-dry-build`).
*   **Signing:** All commits must be GPG signed.