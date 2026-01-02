# Gemini CLI Context

## ⚠️ Primary Context Source
**STOP:** Before proceeding, read **[.context/index.md](.context/index.md)**.
This directory is the **Single Source of Truth** for this project.

*   **Standards & Protocols:** `.context/global/`
*   **Project Specifics:** `.context/project/`

## Project Overview
This is a NixOS configuration repository using `blueprint` for structure. It manages NixOS and Darwin hosts.

## AI Agent Workflow
1.  **Read Instructions:** Check `.context/index.md` and linked files.
2.  **Plan First:** Create a plan and confirm with the user.
3.  **Safety:** Explain destructive actions. Use `read_file` to verify state.

## Specialized Instructions
Refer to `.context/project/agents/` for detailed instructions on:
*   **Secrets Management (`agenix`)**: `.context/project/agents/agenix.md`
*   **Containers (`containnix`)**: `.context/project/agents/containnix.md`
*   **Cloudflare (`cfnix`)**: `.context/project/agents/cfnix.md`
*   **Packaging (`nix-packager`)**: `.context/project/agents/nix-packager.md`

## Common Recipes
*   **Create Database:** `.context/project/recipes/create-db.md`
*   **Create Pi Host:** `.context/project/recipes/create-pi-host.md`

## Development Conventions
*   **Modularity:** Reuse modules in `modules/`.
*   **Secrets:** NEVER commit unencrypted secrets.
*   **Build & Deploy:**
    *   `nixos-rebuild switch --flake .#<hostname>`
    *   `make remote-rebuild remotehost=<hostname>`

## Git Workflow
*   **Feature Branches:** Always work on a feature branch (`feat/`, `fix/`).
*   **Verification:** Verify builds (`make remote-dry-build`).
*   **Signing:** All commits must be GPG signed.
*   **Global Improvements:** If you improve the Global Standards (`.context/global/`), you MUST contribute these back to the source of truth. Create a PR at [github.com/iamruinous/nix-config](https://github.com/iamruinous/nix-config).
