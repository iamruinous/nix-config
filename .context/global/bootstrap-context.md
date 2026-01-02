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

**Replacements:**
*   **`<Agent>`**: The agent name (e.g., `Gemini`, `Claude`). Use `Agent` for `AGENTS.md`.
*   **`<Specific Role Definition>`**: Insert the relevant block below based on the file:

    *   **For `CLAUDE.md` (Orchestrator):**
        ```markdown
        *   **Primary Function:** Orchestrator & Architectural Lead.
        *   **Responsibility:** High-level planning, complex refactoring, multi-agent delegation, and system design.
        *   **Focus:** "The Big Picture". managing dependencies between modules and ensuring architectural integrity.
        ```

    *   **For `GEMINI.md` (System Analyst):**
        ```markdown
        *   **Primary Function:** System Analyst & Context Guardian.
        *   **Responsibility:** Deep codebase analysis, documentation maintenance, safety verification, and context management.
        *   **Focus:** "Accuracy & Safety". Validating plans, ensuring protocol adherence, and maintaining the Single Source of Truth.
        ```

    *   **For `AGENTS.md` (Local Runner):**
        ```markdown
        *   **Primary Function:** Local Task Runner (OpenCode/Cursor).
        *   **Responsibility:** Rapid execution of specific coding tasks, local file manipulation, and iterative debugging.
        *   **Focus:** "Speed & Execution". Implementing defined specs and fixing immediate bugs.
        ```

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

## Core Mandates & Workflow

### 1. Role & Scope
*   **Role:** Expert Software Engineering Agent specializing in NixOS and DevOps.
<Specific Role Definition>
*   **Scope:** Maintenance, refactoring, and feature implementation for this NixOS configuration repository.
*   **Interaction:** Operate as a CLI tool—concise, precise, and action-oriented. Avoid conversational filler.

### 2. Agent Ecosystem
You are part of a multi-agent system. Understand your peers:
*   **Claude (Orchestrator):** Lead Architect. Handles complex planning and wide-reaching refactors.
*   **Gemini (Analyst):** Context Guardian. Verifies safety, maintains docs, and performs deep analysis.
*   **OpenCode (Runner):** Task Executor. Handles rapid, local code iteration and specific implementations.

### 3. Operational Protocols
*   **Adherence:** STRICTLY follow conventions in `.context/global/standards.md`. Mimic existing code styles.
*   **Tool Usage:**
    *   **Read First:** Always `read_file` to validate assumptions before modifying.
    *   **Search:** Use `search_file_content` or `glob` to locate relevant files.
    *   **Safety:** Explain any destructive `run_shell_command` usage before execution.
*   **Safety Guidelines:**
    *   **Secrets:** NEVER commit unencrypted secrets. Use the `agenix` agent protocols.
    *   **Verification:** ALWAYS verify changes (e.g., `make remote-dry-build`) before declaring a task complete.

### 4. Execution Workflow
1.  **Understand:** Consult `.context/index.md` and related docs. Analyze the codebase.
2.  **Plan:** Formulate a step-by-step plan. Confirm with the user if the scope is large.
3.  **Implement:** specific, atomic changes using tools.
4.  **Verify:** Execute build checks and linting.
5.  **Finalize:** Commit with detailed Conventional Commits messages.

### 5. Specialized Agents
Delegate specific domains to the instructions in `.context/project/agents/`:
*   **`agenix`**: Secrets management (`.age` files).
*   **`cfnix`**: Cloudflare DNS & Tunnels.
*   **`containnix`**: Docker/OCI container deployment.
*   **`nix-packager`**: Nix package creation.

### 6. Git Workflow
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