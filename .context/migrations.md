# Context Migrations Log

This file tracks the evolution of the Multi-Agent System (MAS) context structure.
**Source of Truth:** [github.com/iamruinous/nix-config](https://github.com/iamruinous/nix-config)

---

## [2025.01.02] - oh-my-opencode Standardization
**Type:** Major Migration

### Summary

Standardized on **[oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)** as the primary AI agent interface, with **Sisyphus** (Claude Opus 4.5) as the orchestrator.

### Key Changes

| Component | Before | After |
|-----------|--------|-------|
| **Primary Interface** | Multiple CLIs (Gemini, Claude, OpenCode) | OpenCode + oh-my-opencode |
| **Orchestrator** | Hub-and-Spoke (manual) | Sisyphus (automated) |
| **Primary Beacon** | Split across AGENTS/GEMINI/CLAUDE.md | AGENTS.md only |
| **Agent Definitions** | `.context/project/agents/` | `.claude/agents/` |
| **Configuration** | None | `.opencode/oh-my-opencode.jsonc` |

### Benefits

1. **Single orchestrator** - Sisyphus handles planning/delegation automatically
2. **Background agents** - True parallel execution without context duplication
3. **Built-in specialists** - Oracle, Librarian, Explore, Frontend Engineer, etc.
4. **Claude Code compatibility** - Existing `.claude/` structure works seamlessly
5. **MCP integration** - Context7, Exa search, grep.app built-in

### Files Changed

| File | Change |
|------|--------|
| `AGENTS.md` | Complete rewrite as primary oh-my-opencode context |
| `GEMINI.md` | Updated to reference AGENTS.md as primary |
| `CLAUDE.md` | Updated to reference AGENTS.md as primary |
| `.context/index.md` | Updated for OpenCode as primary interface |
| `.context/global/protocols.md` | Updated for Sisyphus orchestration |
| `.context/project/roster.md` | Mapped to oh-my-opencode agent system |
| `.context/replicating-setup.md` | Complete rewrite with migration guide |
| `docs/plans/multi-agent-orchestration.md` | Marked as implemented |
| `README.md` | Updated AI Agent Workflow section |

### New Files

| File | Purpose |
|------|---------|
| `.opencode/oh-my-opencode.jsonc` | Project-specific oh-my-opencode configuration |

### Manual Migration Steps

If migrating from the previous multi-CLI system:

1. **Install oh-my-opencode**
   ```bash
   bunx oh-my-opencode install
   ```

2. **Update AGENTS.md**
   - Rewrite as the primary context beacon
   - Include oh-my-opencode quick start
   - Document both built-in and project agents

3. **Update secondary beacons**
   - GEMINI.md and CLAUDE.md should reference AGENTS.md
   - Keep for backwards compatibility with direct CLI usage

4. **Update .context/ files**
   - `index.md`: Reference OpenCode as primary
   - `global/protocols.md`: Add Sisyphus orchestration
   - `project/roster.md`: Map to oh-my-opencode agents

5. **Create configuration**
   - Create `.opencode/oh-my-opencode.jsonc`
   - Update `.gitignore` for new patterns

6. **Verify agents load**
   - Existing `.claude/agents/*.md` files work as-is
   - Test with `opencode` and invoke agents

### Breaking Changes

- **Agent location unchanged** - `.claude/agents/` still works
- **Protocols updated** - Review `global/protocols.md` for new patterns
- **Primary beacon changed** - AGENTS.md is now the main context file

---

## [2025.01.03] - Upgrade Protocol & Context Loading Directive
**Type:** Feature

### Summary
Introduced two major protocols:
1.  **Context Loading Directive (CLD):** Forces agents to verify environment integrity before starting.
2.  **Upgrade Protocol:** Standardized how we version and document changes to the context system itself.

### Manual Upgrade Steps

## Initializing a new Repository with Context

1.  **Create Directory:** `mkdir -p .context/{global,project}`
2.  **Add Core Files:** Copy index, protocols, standards from a source repo.
3.  **Update Beacons:** Initialize `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` using the bootstrap protocol.
4.  **Update Makefile:** Add `bootstrap-context` target.

#### 2. Implement Upgrade Protocol
1.  **Create File:** Create `.context/global/upgrades.md` (this protocol definition).
2.  **Create Log:** Create `.context/migrations.md` (this file).
3.  **Update Index:** Add links to these new files in `.context/index.md`.

## [2026.01.02] - Manual Bootstrap Protocol & Agent Roles
**Type:** Refactor

### Summary
Replaced the automated `make bootstrap-context` script with a manual protocol to reduce complexity and reliance on external scripts.
1.  **Manual Protocol:** Defined in `.context/global/bootstrap-context.md`.
2.  **Agent Roles:** Added specific role definitions for Claude (Orchestrator), Gemini (Analyst), and OpenCode (Runner) to the context template.
3.  **Cleanup:** Removed `scripts/bootstrap-context.sh` and the Makefile target.

### Manual Upgrade Steps
1.  **Read Protocol:** Review `.context/global/bootstrap-context.md`.
2.  **Bootstrap Beacons:** Manually update `GEMINI.md`, `CLAUDE.md`, and `AGENTS.md` following the new protocol.
