# Claude Memory & Scratchpad

## 🧠 Active Context
*   **Role:** Orchestrator (Hub)

## 📝 Memories
*   (No active memories)

<!-- CONTEXT_BOOTSTRAP_START - DO NOT EDIT BELOW THIS LINE -->
# Claude CLI Context (Bootstrapped)

## ⚠️ Primary Context Source
Your context is managed via this bootstrapped beacon. The **Single Source of Truth** is located in **[.context/index.md](.context/index.md)**.

*   **Standards & Protocols:** `.context/global/`
*   **Project Specifics:** `.context/project/`

## Project Overview
This is a NixOS configuration repository using `blueprint` for structure. It manages NixOS and Darwin hosts.
*   **Switch:** `nixos-rebuild switch --flake .#<host>`
*   **Remote:** `make remote-rebuild remotehost=<host>`

## AI Agent Workflow
You are an intelligent coding assistant. Your primary goal is to help the user safely and efficiently.

### 1. Plan & Orchestrate
*   **Check Context:** Always reference `.context/` files.
*   **Create Plan:** Use the TodoWrite tool (or similar) to outline your steps.
*   **Confirm:** Get user approval before executing complex changes.

### 2. Specialized Agents
This project defines specialized agent personas. When dealing with specific domains, delegate (mentally) to the instructions found in `.context/project/agents/`:
*   **`agenix`**: Secrets management (`.age` files).
*   **`cfnix`**: Cloudflare DNS & Tunnels.
*   **`containnix`**: Docker/OCI container deployment.
*   **`nix-packager`**: Nix package creation.

### 3. Git Workflow
*   **Branch:** Always work on a feature branch (`feat/`, `fix/`).
*   **Draft PR:** Create a draft PR early to track progress.
*   **Verify:** Run `make remote-dry-build remotehost=<host>` before committing.
*   **Sign:** GPG sign all commits.
*   **Global Improvements:** If you improve the Global Standards (`.context/global/`), you MUST contribute these back to the source of truth. Create a PR at [https://github.com/iamruinous/nix-config](https://github.com/iamruinous/nix-config).

## Secrets Management
**CRITICAL:** Never commit unencrypted secrets.
*   Use `agenix` for all secrets.
*   See `.context/project/agents/agenix.md` for detailed workflows.

## Common Recipes
*   **Create Database:** See `.context/project/recipes/create-db.md`
*   **Create Pi Host:** See `.context/project/recipes/create-pi-host.md`
