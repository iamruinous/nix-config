# Context Beacon (Index)
**System Version:** 2025.01.02

This directory (`.context/`) is the **Single Source of Truth** for AI agents working on this repository. It separates global standards from project-specific configuration.

## Primary Interface

**[OpenCode](https://opencode.ai) with [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)** is the primary AI agent interface for this project.

- **AGENTS.md** - Main context beacon for OpenCode/Sisyphus
- **Orchestrator:** Sisyphus (Claude Opus 4.5)
- **Magic Word:** Include `ultrawork` or `ulw` in prompts for maximum performance

### Alternative Interfaces (Secondary)
- `GEMINI.md` - Gemini CLI memory beacon
- `CLAUDE.md` - Claude CLI memory beacon

---

## Global (Standards & Protocols)
*Shared patterns applicable across repositories.*

*   **Protocols:** [.context/global/protocols.md](./global/protocols.md) (Sisyphus Orchestration, Delegation)
*   **Upgrades:** [.context/global/upgrades.md](./global/upgrades.md) (Migration & Versioning)
*   **Git Workflow:** [.context/global/git.md](./global/git.md) (Branching, PRs, Commit styles)
*   **Coding Standards:** [.context/global/standards.md](./global/standards.md) (Style, Security, Testing)
*   **MCP Standards:** [.context/global/mcp.md](./global/mcp.md) (MCP server management)
*   **Context Bootstrap:** [.context/global/bootstrap-context.md](./global/bootstrap-context.md) (Self-healing context)
*   **Replication Guide:** [.context/replicating-setup.md](./replicating-setup.md) (How to set this up in a new repo)

## Project (Specifics)
*Configuration unique to `iamruinous/nix-config`.*

*   **Architecture:** [.context/project/architecture.md](./project/architecture.md) (Directory structure, Tech stack)
*   **Agent Roster:** [.context/project/roster.md](./project/roster.md) (Active agents & Delegation matrix)
*   **MCP Registry:** [.context/project/mcp-registry.md](./project/mcp-registry.md) (Active MCP servers)
*   **Agent Instructions:** `.claude/agents/` (Custom agent definitions for oh-my-opencode)
*   **Slash Commands:** `.claude/commands/` (Custom commands for oh-my-opencode)
*   **Recipes:** `.context/project/recipes/` (Common workflows)

## oh-my-opencode Integration

### Agent System

oh-my-opencode provides built-in agents that work alongside project-specific agents:

| Type | Agents | Location |
|------|--------|----------|
| **Built-in** | oracle, librarian, explore, frontend-ui-ux-engineer, document-writer, multimodal-looker | oh-my-opencode |
| **Project** | agenix, cfnix, containnix, nix-packager | `.claude/agents/` |

### Configuration Files

| File | Purpose |
|------|---------|
| `.opencode/oh-my-opencode.json` | Project-specific oh-my-opencode config |
| `~/.config/opencode/oh-my-opencode.json` | User-level oh-my-opencode config |
| `.claude/settings.local.json` | Local Claude Code compatible settings |

---

## Maintenance
*Instructions for keeping this context updated.*

*   **Changelog:** [.context/migrations.md](./migrations.md) (Track context updates here)

1.  **Update on Creation:** When creating a new file in `.context/`, you MUST update this index.
2.  **Verify Links:** Ensure all links remain functional after refactoring.
3.  **Cross-Reference:** Update relevant global or project documents when adding new capabilities.

## Quick Start for Agents

1.  **Read AGENTS.md:** Primary context for OpenCode/Sisyphus
2.  **Read Architecture:** Understand repo layout in `project/architecture.md`
3.  **Check Roster:** See delegation matrix in `project/roster.md`
4.  **Execute:** Follow `global/git.md` for all changes
5.  **Verify:** Run `make remote-dry-build remotehost=<target>` before completing
