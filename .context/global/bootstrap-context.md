# Context Bootstrap Protocol

## Overview

This document defines the bootstrap protocol for AI agent context files. The primary interface is **OpenCode with oh-my-opencode**, but secondary beacon files (`GEMINI.md`, `CLAUDE.md`) are maintained for backwards compatibility.

## Primary vs Secondary Interfaces

| Interface | File | Status |
|-----------|------|--------|
| **OpenCode + oh-my-opencode** | `AGENTS.md` | **PRIMARY** |
| Gemini CLI | `GEMINI.md` | Secondary |
| Claude CLI | `CLAUDE.md` | Secondary |

**AGENTS.md** is the authoritative context source. Secondary beacons reference it.

---

## When to Bootstrap

1. When initializing a new repository with the context system
2. When the structure of `.context/` changes significantly
3. When migrating to a new version (see `migrations.md`)
4. If context in beacon files appears outdated

---

## AGENTS.md (Primary Beacon)

AGENTS.md is loaded by oh-my-opencode via the Claude Code compatibility layer. It should contain:

1. **Quick Start** - How to launch OpenCode with Sisyphus
2. **Project Overview** - Brief description and key commands
3. **Agent System** - Both built-in and project-specific agents
4. **Delegation Matrix** - When to use which agent
5. **Verification Protocol** - How to verify task completion
6. **Context Pointers** - Links to `.context/` files

### Template Structure

```markdown
# [Project Name] - Agent Context

**Primary Interface:** [OpenCode](https://opencode.ai) with [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)  
**Orchestrator:** Sisyphus (Claude Opus 4.5)  
**Context Version:** YYYY.MM.DD

---

## Quick Start
[How to start OpenCode]

## Project Overview
[Brief description, key commands]

## Agent System
[Built-in and project agents]

## Delegation Matrix
[When to use which agent]

## Verification Protocol
[How to verify completion]

## Context System
[Links to .context/ files]
```

---

## Secondary Beacons (GEMINI.md, CLAUDE.md)

Secondary beacons support direct CLI usage. They follow a split structure:

### Structure

```
┌─────────────────────────────────────┐
│ TOP: Mutable (User Memory)          │
│ - Active context notes              │
│ - Session memories                  │
├─────────────────────────────────────┤
│ DELIMITER                           │
├─────────────────────────────────────┤
│ BOTTOM: Immutable (Bootstrap)       │
│ - Context pointers                  │
│ - Quick reference                   │
└─────────────────────────────────────┘
```

### Delimiter

```markdown
<!-- CONTEXT_BOOTSTRAP_START - DO NOT EDIT BELOW THIS LINE -->
```

**Agents MUST NOT edit anything below this line.**

### Procedure for Updating Secondary Beacons

1. **Read** the current file content
2. **Locate** the delimiter line
3. **Preserve** everything above the delimiter (user memory)
4. **Replace** everything below with the standard template
5. **Write** the combined content

### Secondary Beacon Template

```markdown
# [Agent] CLI Context (Bootstrapped)

## Primary Context Source
Your context is managed via this bootstrapped beacon. The **Single Source of Truth** is located in **[.context/index.md](.context/index.md)**.

**Preferred Interface:** [OpenCode](https://opencode.ai) with [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)  
**Main Context:** [AGENTS.md](./AGENTS.md)

*   **Standards & Protocols:** `.context/global/`
*   **Project Specifics:** `.context/project/`
*   **Custom Agents:** `.claude/agents/`

## Project Overview
[Brief project description]

## AI Agent Workflow
You are an intelligent coding assistant. Your primary goal is to help the user safely and efficiently.

### 1. Plan & Orchestrate
*   **Check Context:** Reference `AGENTS.md` and `.context/` files
*   **Create Plan:** Use the TodoWrite tool to outline your steps
*   **Confirm:** Get user approval before executing complex changes

### 2. Specialized Agents
This project defines specialized agent personas in `.claude/agents/`:
*   [List your project agents]

### 3. Git Workflow
*   **Branch:** Always work on a feature branch (`feat/`, `fix/`)
*   **Draft PR:** Create a draft PR early to track progress
*   **Verify:** Run build/test commands before committing
*   **Sign:** GPG sign all commits

## Secrets Management
**CRITICAL:** Never commit unencrypted secrets.
*   [Your secrets management instructions]

## Common Recipes
*   [Links to your recipes]
```

---

## Agent Roles (Historical)

Prior to oh-my-opencode, we defined explicit roles for each CLI:

| CLI | Role | Note |
|-----|------|------|
| Claude | Orchestrator | Now handled by Sisyphus |
| Gemini | Analyst | Now handled by librarian/explore |
| OpenCode | Runner | Now the primary interface |

With oh-my-opencode, Sisyphus handles orchestration and delegates to specialized agents automatically.

---

## oh-my-opencode Agent System

oh-my-opencode provides built-in agents:

| Agent | Purpose |
|-------|---------|
| **oracle** | Architecture, debugging, strategy |
| **librarian** | Documentation, OSS examples |
| **explore** | Fast codebase exploration |
| **frontend-ui-ux-engineer** | Visual/UI development |
| **document-writer** | Technical documentation |
| **multimodal-looker** | PDF/image/diagram analysis |

Project-specific agents are defined in `.claude/agents/` and loaded automatically.

---

## Verification

After bootstrapping, verify with:

```bash
# Start OpenCode
opencode

# Test context loading
# The agent should reference AGENTS.md and .context/ automatically
```
