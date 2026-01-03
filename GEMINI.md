# Gemini Memory & Scratchpad

## Primary Interface Notice

**OpenCode with oh-my-opencode** is the primary AI agent interface for this project.  
For complete context, see **[AGENTS.md](./AGENTS.md)**.

---

## Active Context
*   **Role:** Secondary Interface
*   **Primary:** Use OpenCode + Sisyphus for best experience

## Memories
- We are designing an 'Adaptive Parameters System' for Messy/Newsy to manage dynamic user facts, preferences, and system configuration with versioning and MCP tool exposure. Design doc is at docs/plans/adaptive-parameters-system.md.

<!-- CONTEXT_BOOTSTRAP_START - DO NOT EDIT BELOW THIS LINE -->
# Gemini CLI Context (Bootstrapped)

## Primary Context Source
Your context is managed via this bootstrapped beacon. The **Single Source of Truth** is located in **[.context/index.md](.context/index.md)**.

**Preferred Interface:** [OpenCode](https://opencode.ai) with [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)  
**Main Context:** [AGENTS.md](./AGENTS.md)

*   **Standards & Protocols:** `.context/global/`
*   **Project Specifics:** `.context/project/`
*   **Custom Agents:** `.claude/agents/`

## Project Overview
This is a NixOS configuration repository using `blueprint` for structure. It manages NixOS and Darwin hosts.
*   **Switch:** `nixos-rebuild switch --flake .#<host>`
*   **Remote:** `make remote-rebuild remotehost=<host>`

## AI Agent Workflow
You are an intelligent coding assistant. Your primary goal is to help the user safely and efficiently.

### 1. Plan & Orchestrate
*   **Check Context:** Reference `AGENTS.md` and `.context/` files
*   **Create Plan:** Use the TodoWrite tool (or similar) to outline your steps
*   **Confirm:** Get user approval before executing complex changes

### 2. Specialized Agents
This project defines specialized agent personas in `.claude/agents/`:
*   **`agenix`**: Secrets management (`.age` files)
*   **`cfnix`**: Cloudflare DNS & Tunnels
*   **`containnix`**: Docker/OCI container deployment
*   **`nix-packager`**: Nix package creation

### 3. Git Workflow
*   **Branch:** Always work on a feature branch (`feat/`, `fix/`)
*   **Draft PR:** Create a draft PR early to track progress
*   **Verify:** Run `make remote-dry-build remotehost=<host>` before committing
*   **Sign:** GPG sign all commits

## Secrets Management
**CRITICAL:** Never commit unencrypted secrets.
*   Use `agenix` for all secrets
*   See `.claude/agents/agenix.md` for detailed workflows

## Common Recipes
*   **Create Database:** See `.context/project/recipes/create-db.md`
*   **Create Pi Host:** See `.context/project/recipes/create-pi-host.md`
