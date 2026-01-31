# Proposal: Deep Git Worktree Integration for Ruinous.AI

## 1. Executive Summary

This proposal outlines the architecture for a "Zero-Friction" Git Worktree workflow within the Ruinous.AI ecosystem. The goal is to make creating, switching, and destroying isolated development environments (worktrees) as fluid as opening a new browser tab.

This system will seamlessly integrate:
-   **Git Worktrees:** For filesystem-level isolation of branches.
-   **Tmux/Tmuxp:** For terminal session/window management.
-   **Neovim:** For editor context.
-   **AI Agents (Claude, Gemini, OpenCode):** For isolated agent memory and context.

## 2. Philosophy: "The Invisible Workspace"

The core philosophy is **Session Isolation**.
When a user (or agent) starts a task, they should enter a "bubble" containing:
1.  The specific code version (branch).
2.  The runtime environment (`.env`, `direnv`).
3.  The editor state.
4.  The AI agent's context (chat history, active tasks).

Switching bubbles should be instant. Destroying a bubble should leave no trace.

## 3. Directory Architecture

We will adopt a hybrid "Bare Repository" pattern to support the requested structure.

**Standard Project Location:** `~/Projects/ruinage/<project>`
**Worktree Storage:** `~/Projects/.worktrees/ruinage/<project>/<feature-name>`

### Structure Layout
```text
~/Projects/ruinage/nix-config/        # (Symlink) -> Points to the "Active" or "Main" worktree
~/Projects/.worktrees/ruinage/nix-config/
├── .bare/                            # The actual git directory (bare repo)
├── main/                             # The primary branch worktree
├── feature-cluster-auth/             # Worktree for feature A
└── fix-dns-race/                     # Worktree for fix B
```

**Migration Strategy:**
Existing repositories can be converted to this structure non-destructively, or we can support a "Mixed" mode where the `.git` dir stays in `~/Projects/...` and worktrees live in `.worktrees`.
*Recommendation:* Move to Bare Repo pattern for new projects. Use "Linked Worktree" pattern for existing ones to avoid breaking absolute paths in existing configs.

## 4. The Orchestrator: `wt` (Worktree Tool)

We will implement a shell-based orchestrator (likely a ZSH function + Nix package) named `wt` (or `rwt` for Ruinous WorkTree).

### Key Commands

| Command | Action |
| :--- | :--- |
| `wt new <branch> [task-prompt]` | Creates worktree, sets up env, opens tmux window, seeds agent. |
| `wt switch <branch>` | Switches tmux focus to the existing worktree window. |
| `wt list` | Lists active worktrees with status (clean/dirty, active agents). |
| `wt kill <branch>` | Safely removes worktree, kills tmux process, cleans git branch. |
| `wt pause` | "Suspends" the worktree (detaches tmux, maybe stops dev servers). |

## 5. Integration Deep-Dive

### 5.1. Environment & Configs (`direnv` + `.env`)
**Problem:** New worktrees are empty. They lack `.env` and ignored files.
**Solution:** `post-create` hook.
1.  Copy `.env` and `.env.secrets` from the "Main" worktree (or a designated template).
2.  Run `direnv allow` automatically.
3.  Symlink `node_modules` or `target` directories if strict isolation isn't required (configurable per project via `.wt.yaml`), to save disk space/build time.

### 5.2. Tmux & Tmuxp
**Integration:**
*   **One Worktree = One Tmux Window.**
*   The Window Name matches the Worktree Name.
*   **Project-Defined Defaults:** The repository root can contain a `.worktree-layout.yaml` (or similar) defining the standard `tmuxp` layout for that project (e.g., "Left: Neovim, Right Top: Server, Right Bottom: Agent").
*   When `wt new` runs, it loads this template, substitutes the worktree path, and launches the session.

### 5.3. Neovim
**Integration:**
*   Neovim is launched with `cwd` set to the worktree root.
*   We can use a neovim plugin (or simple autocmd) that updates the status line to show the "Worktree Context".
*   *Bonus:* Shared session management (auto-save session on exit, auto-load on enter).

### 5.4. AI Agent Integration (The "Deep" Part)
**Problem:** Agents need to know *what* they are working on and *where*.
**Solution:**
1.  **Context Seeding:** When running `wt new "refactor-auth" "Switch to OIDC"`, the tool creates a `AGENTS.md` or `.context.md` in the worktree root containing the task prompt.
2.  **Agent Wrappers:** The `claude`, `gemini`, or `opencode` commands in the shell are wrapped to prioritize the local worktree context.
3.  **Isolation:** Since the agent runs in the worktree's filesystem, file modifications are naturally isolated.

### 5.5. Ruinous Login Hub Integration
**Integration:**
*   **Menu "Select Worktree":** The TUI will list active worktrees (discovered via `~/.config/tmuxp/` or `wt list`). Selecting one attaches to the corresponding tmux session/window.
*   **Menu "Create New Worktree":** A new top-level option.
    *   **Interaction:** Prompts user for 1) Project (if multiple), 2) New Branch Name, 3) (Optional) Task Prompt.
    *   **Action:** Executes `wt new ...` in the background.
    *   **Result:** Automatically attaches to the newly created environment using the project's defined defaults (tmux layout, env vars, etc.).

## 6. Proposed Workflow Example

1.  **User:** `wt new feat/k8s-upgrade "Upgrade clusters to 1.30"`
2.  **System:**
    *   Creates `~/Projects/.worktrees/ruinage/nix-config/feat-k8s-upgrade`.
    *   Copies `.env`.
    *   Writes "Upgrade clusters to 1.30" to `.sisyphus/task.md`.
    *   Creates Tmux Window: `nix-config/feat-k8s-upgrade`.
    *   Splits panes:
        *   Pane 1: Neovim (opened to `flake.nix`).
        *   Pane 2: Shell (running `direnv allow`).
        *   Pane 3: `gemini` (pre-loaded with "I see a task in .sisyphus/task.md, shall I start?").
3.  **User:** Works...
4.  **User:** `wt switch main` (Switches window to check something).
5.  **User:** `wt kill feat/k8s-upgrade` (Merges PR, deletes worktree & window).

## 7. Next Steps

1.  **Refine Scripts:** Prototype the `wt` function in `modules/home/common/shell/worktree.nix` (or similar).
2.  **Define `.wt.yaml`:** Create a configuration schema for project-specific overrides (files to copy, commands to run).
3.  **Tmuxp Template:** Design the "Standard Agent Layout".
4.  **Agent Prompting:** Update `gemini` system instructions to look for local task files.

---
*Generated by Gemini CLI - 2026-01-31*
