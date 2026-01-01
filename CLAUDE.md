# AI Agent Context

## ⚠️ Primary Context Source
**STOP:** Before proceeding, read the files in the `.context/` directory. This is the **Single Source of Truth** for this project.

*   **Project Overview & Architecture:** `.context/project-context.md`
*   **Coding & Git Standards:** `.context/standards.md`
*   **Agent Capabilities & Recipes:** `.context/agents/` and `.context/recipes/`

## Project Overview
This is a NixOS configuration repository using `blueprint` for structure. It manages NixOS and Darwin hosts.
*   **Switch:** `nixos-rebuild switch --flake .#<host>`
*   **Remote:** `make remote-rebuild remotehost=<host>`

## AI Agent Workflow
You are an intelligent coding assistant. Your primary goal is to help the user safely and efficiently.

### 1. Plan & Orchestrate
*   **Check Context:** Always reference `.context/` files for patterns (e.g., how to add a container, how to manage secrets).
*   **Create Plan:** Use the TodoWrite tool (or similar) to outline your steps.
*   **Confirm:** Get user approval before executing complex changes.

### 2. Specialized Agents
This project defines specialized agent personas. When dealing with specific domains, adopt the persona or delegate (mentally) to the instructions found in `.context/agents/`:
*   **`agenix`**: Secrets management (`.age` files).
*   **`cfnix`**: Cloudflare DNS & Tunnels.
*   **`containnix`**: Docker/OCI container deployment.
*   **`nix-packager`**: Nix package creation.

### 3. Git Workflow
*   **Branch:** Always work on a feature branch (`feat/`, `fix/`).
*   **Draft PR:** Create a draft PR early to track progress.
*   **Verify:** Run `make remote-dry-build remotehost=<host>` before committing.
*   **Sign:** GPG sign all commits.

## Secrets Management
**CRITICAL:** Never commit unencrypted secrets.
*   Use `agenix` for all secrets.
*   See `.context/agents/agenix.md` for detailed workflows.

## Common Recipes
*   **Create Database:** See `.context/recipes/create-db.md`
*   **Create Pi Host:** See `.context/recipes/create-pi-host.md`