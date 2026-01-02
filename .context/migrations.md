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

#### 1. Implement Context Loading Directive
1.  **Create Script:** Copy `scripts/context-check.sh` from source.
2.  **Update Makefile:** Add `context-check` target.
3.  **Update Beacons:** Update `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` to mandate `make context-check`.
4.  **Update Protocols:** Add "0. Initialization Phase" to `.context/global/protocols.md`.

#### 2. Implement Upgrade Protocol
1.  **Create File:** Create `.context/global/upgrades.md` (this protocol definition).
2.  **Create Log:** Create `.context/migrations.md` (this file).
3.  **Update Index:** Add links to these new files in `.context/index.md`.
