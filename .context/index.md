# Context Beacon (Index)
**System Version:** 2025.01.03

This directory (`.context/`) is the **Single Source of Truth** for AI agents working on this repository. It separates global standards from project-specific configuration.

## 🌍 Global (Standards & Protocols)
*Shared patterns applicable across repositories.*

*   **Protocols:** [.context/global/protocols.md](./global/protocols.md) (Hub-and-Spoke model, Planning)
*   **Upgrades:** [.context/global/upgrades.md](./global/upgrades.md) (Migration & Versioning)
*   **Git Workflow:** [.context/global/git.md](./global/git.md) (Branching, PRs, Commit styles)
*   **Coding Standards:** [.context/global/standards.md](./global/standards.md) (Style, Security, Testing)
*   **MCP Standards:** [.context/global/mcp.md](./global/mcp.md) (MCP server management)
*   **Context Bootstrap:** [.context/global/bootstrap-context.md](./global/bootstrap-context.md) (Self-healing context)
*   **Replication Guide:** [.context/replicating-setup.md](./replicating-setup.md) (How to set this up in a new repo)

## 🏗️ Project (Specifics)
*Configuration unique to `iamruinous/nix-config`.*

*   **Architecture:** [.context/project/architecture.md](./project/architecture.md) (Directory structure, Tech stack)
*   **Agent Roster:** [.context/project/roster.md](./project/roster.md) (Active agents & Delegation matrix)
*   **MCP Registry:** [.context/project/mcp-registry.md](./project/mcp-registry.md) (Active MCP servers)
*   **Agent Instructions:** `.context/project/agents/` (Persona definitions)
*   **Recipes:** `.context/project/recipes/` (Common workflows)

## 🛠️ Maintenance
*Instructions for keeping this context updated.*

*   **Changelog:** [.context/migrations.md](./migrations.md) (Track context updates here)

1.  **Update on Creation:** When creating a new file in `.context/`, you MUST update this index.
2.  **Verify Links:** Ensure all links remain functional after refactoring.
3.  **Cross-Reference:** Update relevant global or project documents when adding new capabilities.

## 🚀 Quick Start for Agents
1.  **Read Protocols:** Understand the planning phase in `global/protocols.md`.
2.  **Read Architecture:** Understand the repo layout in `project/architecture.md`.
3.  **Check Roster:** See who to delegate to in `project/roster.md`.
4.  **Execute:** Follow `global/git.md` for all changes.
