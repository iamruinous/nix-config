# Context Migrations Log

This file tracks the evolution of the Multi-Agent System (MAS) context structure.
**Source of Truth:** [github.com/iamruinous/nix-config](https://github.com/iamruinous/nix-config)

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
