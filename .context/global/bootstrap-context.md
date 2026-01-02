# Manual Context Bootstrap

## Purpose
This guide defines the procedure for an AI agent to manually update the immutable context section of beacon files (`GEMINI.md`, `CLAUDE.md`, `AGENTS.md`). This ensures the agents always have the latest pointers to the **Single Source of Truth** in `.context/`.

## When to Run
1.  When initializing a new agent environment.
2.  When the structure of `.context/` changes.
3.  When the user explicitly requests to "refresh" or "bootstrap" the context.
4.  If you notice the context in `GEMINI.md` or `CLAUDE.md` is outdated or missing.

## Procedure

### 1. Identify Target Files
The target files are located in the project root:
*   `GEMINI.md`
*   `CLAUDE.md`
*   `AGENTS.md`

### 2. Read and Parse
For each target file:
1.  Read the current content of the file.
2.  Locate the delimiter:
    ```markdown
    <!-- CONTEXT_BOOTSTRAP_START - DO NOT EDIT BELOW THIS LINE -->
    ```
3.  **Preserve** everything *above* this delimiter. This is the "User Memory & Scratchpad" area.
    *   *If the delimiter is missing:* Preserve the entire file (assume it's all memory) and append the delimiter.

### 3. Construct New Content
Create the new file content by combining:
1.  The **Preserved User Memory**.
2.  The **Delimiter** (exactly as shown above).
3.  The **Standard Context Template** (below).

**Important:** Replace `<Agent>` in the template with the specific agent name (e.g., `Gemini` or `Claude`) or just `Agent` for `AGENTS.md`.

### 4. Write File
Overwrite the target file with the combined content.

---

## Standard Context Template

```markdown
# <Agent> CLI Context (Bootstrapped)

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
```