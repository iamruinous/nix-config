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
