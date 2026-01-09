# Context Index

This directory contains **project-specific** context for AI agents working on this repository.

**Global context** (Codey persona, protocols, standards) is now deployed via `~/.config/opencode/AGENTS.md`.

---

## Project Context

| Path | Purpose |
|------|---------|
| **[AGENTS.md](../AGENTS.md)** | Primary context beacon for OpenCode |
| **[architecture.md](./project/architecture.md)** | Directory structure, tech stack |
| **[roster.md](./project/roster.md)** | Agent delegation matrix |
| **[mcp-registry.md](./project/mcp-registry.md)** | Active MCP servers |

## Custom Agents

| Agent | Location |
|-------|----------|
| **agenix** | [.claude/agents/agenix.md](../.claude/agents/agenix.md) |
| **cfnix** | [.claude/agents/cfnix.md](../.claude/agents/cfnix.md) |
| **containnix** | [.claude/agents/containnix.md](../.claude/agents/containnix.md) |
| **nix-packager** | [.claude/agents/nix-packager.md](../.claude/agents/nix-packager.md) |

## Recipes

| Recipe | Location |
|--------|----------|
| Create Database | [recipes/create-db.md](./project/recipes/create-db.md) |
| Create Pi Host | [recipes/create-pi-host.md](./project/recipes/create-pi-host.md) |

## Slash Commands

Located in `.claude/commands/`:
- `/create-db-<host>` - Create PostgreSQL database
- `/create-pi-host` - Bootstrap Raspberry Pi host
- `/pr` - Create pull request
- `/automerge` - Enable automerge on PR

---

## Maintenance

- **Changelog:** [migrations.md](./migrations.md)
- When adding files to `.context/project/`, update this index
