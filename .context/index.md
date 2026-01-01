# Context Beacon (Index)

This directory (`.context/`) is the **Single Source of Truth** for AI agents working on this repository. It separates global standards from project-specific configuration.

## 🌍 Global (Standards & Protocols)
*Shared patterns applicable across repositories.*

*   **Protocols:** [.context/global/protocols.md](./global/protocols.md) (Hub-and-Spoke model, Planning)
*   **Git Workflow:** [.context/global/git.md](./global/git.md) (Branching, PRs, Commit styles)
*   **Coding Standards:** [.context/global/standards.md](./global/standards.md) (Style, Security, Testing)

## 🏗️ Project (Specifics)
*Configuration unique to `iamruinous/nix-config`.*

*   **Architecture:** [.context/project/architecture.md](./project/architecture.md) (Directory structure, Tech stack)
*   **Agent Roster:** [.context/project/roster.md](./project/roster.md) (Active agents & Delegation matrix)
*   **Agent Instructions:** `.context/project/agents/` (Persona definitions)
*   **Recipes:** `.context/project/recipes/` (Common workflows)

## 🚀 Quick Start for Agents
1.  **Read Protocols:** Understand the planning phase in `global/protocols.md`.
2.  **Read Architecture:** Understand the repo layout in `project/architecture.md`.
3.  **Check Roster:** See who to delegate to in `project/roster.md`.
4.  **Execute:** Follow `global/git.md` for all changes.
