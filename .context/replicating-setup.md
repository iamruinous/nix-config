# Multi-Agent Context System - Replication Guide

**Version:** 2025.01.02  
**Primary Interface:** [OpenCode](https://opencode.ai) with [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)

## Overview

This guide explains how to replicate the multi-agent context system in your own repository. The system uses **oh-my-opencode** with **Sisyphus** as the orchestrator, with a **Single Source of Truth (SSoT)** in the `.context/` directory.

---

## Quick Start (New Repository)

```bash
# 1. Install oh-my-opencode
bunx oh-my-opencode install

# 2. Copy the context structure from this repo
mkdir -p .context/{global,project/agents,project/recipes}
mkdir -p .claude/{agents,commands}
mkdir -p .opencode

# 3. Create your AGENTS.md (see template below)
# 4. Start OpenCode
opencode
```

---

## Architecture Overview

```
your-repo/
├── AGENTS.md                    # PRIMARY: Main context beacon for OpenCode
├── CLAUDE.md                    # SECONDARY: Claude CLI memory (optional)
├── GEMINI.md                    # SECONDARY: Gemini CLI memory (optional)
├── .context/
│   ├── index.md                 # Single Source of Truth index
│   ├── migrations.md            # Context version history
│   ├── replicating-setup.md     # This file
│   ├── global/                  # Reusable standards (copy from source)
│   │   ├── protocols.md         # Sisyphus orchestration protocols
│   │   ├── git.md               # Git workflow standards
│   │   ├── standards.md         # Code quality standards
│   │   ├── mcp.md               # MCP server standards
│   │   └── bootstrap-context.md # Bootstrap protocol
│   └── project/                 # Project-specific (customize)
│       ├── architecture.md      # Tech stack, directory layout
│       ├── roster.md            # Agent delegation matrix
│       ├── mcp-registry.md      # Active MCP servers
│       ├── agents/              # Project-specific agent definitions
│       └── recipes/             # Common workflows
├── .claude/
│   ├── agents/                  # Custom agent definitions (oh-my-opencode loads)
│   │   └── *.md                 # Agent persona files
│   └── commands/                # Slash commands
│       └── *.md                 # Command files
└── .opencode/
    └── oh-my-opencode.jsonc     # Project-specific configuration
```

---

## Step-by-Step Setup

### 1. Install oh-my-opencode

```bash
# Interactive installer
bunx oh-my-opencode install

# Or with specific options
bunx oh-my-opencode install --no-tui --claude=yes --chatgpt=yes --gemini=yes
```

### 2. Create Directory Structure

```bash
# Core directories
mkdir -p .context/{global,project/agents,project/recipes}
mkdir -p .claude/{agents,commands}
mkdir -p .opencode
```

### 3. Copy Global Standards

Copy the `global/` directory from the source repository:

**Source:** [github.com/iamruinous/nix-config/.context/global/](https://github.com/iamruinous/nix-config/tree/main/.context/global)

These files are generally project-agnostic:
- `protocols.md` - Sisyphus orchestration model
- `git.md` - Git workflow standards
- `standards.md` - Code quality standards
- `mcp.md` - MCP server standards
- `bootstrap-context.md` - Bootstrap protocol

### 4. Create AGENTS.md (Primary Beacon)

Create `AGENTS.md` in your repository root:

```markdown
# [Project Name] - Agent Context

**Primary Interface:** [OpenCode](https://opencode.ai) with [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)  
**Orchestrator:** Sisyphus (Claude Opus 4.5)  
**Context Version:** 2025.01.02

---

## Quick Start

\`\`\`bash
opencode
# Include "ultrawork" or "ulw" in prompts for maximum performance
\`\`\`

**Single Source of Truth:** [.context/index.md](.context/index.md)

---

## Project Overview

[Brief description of your project]

### Key Commands

| Action | Command |
|--------|---------|
| **Build** | `your build command` |
| **Test** | `your test command` |
| **Deploy** | `your deploy command` |

---

## Agent System

### Built-in Agents (oh-my-opencode)

| Agent | Purpose |
|-------|---------|
| **oracle** | Architecture, debugging, strategy |
| **librarian** | Documentation, OSS examples |
| **explore** | Fast codebase exploration |
| **frontend-ui-ux-engineer** | Visual/UI development |
| **document-writer** | Technical documentation |

### Project-Specific Agents

| Agent | Purpose |
|-------|---------|
| **your-agent** | Your agent description |

---

## Verification Protocol

Before marking any task complete:
- [ ] Build passes
- [ ] Tests pass
- [ ] All todos marked complete

---

## Context System

| Path | Purpose |
|------|---------|
| `AGENTS.md` | Primary context beacon (this file) |
| `.context/index.md` | Single source of truth |
| `.claude/agents/` | Custom agent definitions |
| `.claude/commands/` | Slash commands |
```

### 5. Create Project-Specific Files

#### `.context/index.md`
```markdown
# Context Beacon (Index)
**System Version:** 2025.01.02

This directory is the **Single Source of Truth** for AI agents.

## Primary Interface
**OpenCode with oh-my-opencode** - See AGENTS.md

## Global (Standards)
- **Protocols:** ./global/protocols.md
- **Git:** ./global/git.md
- **Standards:** ./global/standards.md

## Project (Specifics)
- **Architecture:** ./project/architecture.md
- **Roster:** ./project/roster.md
- **Agents:** .claude/agents/
```

#### `.context/project/architecture.md`
Document your project's:
- Overview and purpose
- Directory structure
- Tech stack
- Build/deploy commands
- Conventions

#### `.context/project/roster.md`
Define your delegation matrix:
- Which agents handle which tasks
- When to use built-in vs project agents
- Parallel execution patterns

### 6. Create Custom Agents (Optional)

Create `.claude/agents/your-agent.md`:

```markdown
---
name: your-agent
description: "Description of what this agent does"
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---

# Your Agent Name

You are an expert in [domain]. You handle [responsibilities].

## Core Commands

\`\`\`bash
# Your agent's key commands
\`\`\`

## Common Patterns

### Pattern 1: [Name]
1. Step one
2. Step two
```

### 7. Configure oh-my-opencode

Create `.opencode/oh-my-opencode.jsonc`:

```jsonc
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",

  // Agent overrides for your project
  "agents": {
    "librarian": {
      "prompt_append": "Project-specific instructions for documentation lookup."
    }
  },

  // Claude Code compatibility enabled
  "claude_code": {
    "mcp": true,
    "commands": true,
    "skills": true,
    "agents": true,
    "hooks": true
  }
}
```

### 8. Update .gitignore

Add to your `.gitignore`:

```gitignore
# Claude Code sensitive files
.claude/settings.json
.claude/settings.local.json
.claude/chats/
.claude/*.local

# OpenCode sensitive files
.opencode/*.local.json
.opencode/*.local.jsonc
```

---

## Migration from Previous System

If you're migrating from the previous multi-CLI system (separate Gemini/Claude/OpenCode contexts):

### Phase 1: Install oh-my-opencode

```bash
bunx oh-my-opencode install
```

### Phase 2: Consolidate Context

1. **AGENTS.md becomes primary** - Rewrite as the main context beacon
2. **GEMINI.md / CLAUDE.md become secondary** - Update to reference AGENTS.md
3. **Move agents to .claude/agents/** - oh-my-opencode loads from here

### Phase 3: Update .context/

| File | Action |
|------|--------|
| `index.md` | Update to reference OpenCode as primary |
| `global/protocols.md` | Update for Sisyphus orchestration |
| `project/roster.md` | Map to oh-my-opencode agent system |

### Phase 4: Create Configuration

1. Create `.opencode/oh-my-opencode.jsonc`
2. Update `.gitignore` for new patterns

### Migration Checklist

- [ ] oh-my-opencode installed
- [ ] AGENTS.md rewritten as primary beacon
- [ ] GEMINI.md / CLAUDE.md updated (if keeping)
- [ ] `.context/index.md` updated
- [ ] `.context/global/protocols.md` updated
- [ ] `.context/project/roster.md` updated
- [ ] Custom agents in `.claude/agents/`
- [ ] `.opencode/oh-my-opencode.jsonc` created
- [ ] `.gitignore` updated
- [ ] Test with `opencode`

---

## Agent Format Reference

### Custom Agent File Format

oh-my-opencode loads agents from `.claude/agents/*.md` using this format:

```markdown
---
name: agent-name
description: "Brief description for agent selection"
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet  # or opus, haiku, etc.
---

# Agent Title

Agent instructions and documentation...
```

### Slash Command Format

Commands in `.claude/commands/*.md`:

```markdown
---
description: "What this command does"
---

# Command Instructions

Steps the agent should follow when this command is invoked...
```

---

## Verification

After setup, verify with:

```bash
# Start OpenCode
opencode

# Test agent loading
# Type: Ask @oracle to review this setup

# Test custom agents (if defined)
# Type: Ask @your-agent to do something
```

---

## Keeping Up to Date

### Sync Global Standards

Periodically sync `global/` from the source:

```bash
# Check for updates
curl -s https://raw.githubusercontent.com/iamruinous/nix-config/main/.context/migrations.md

# Copy updated files as needed
```

### Track Migrations

Maintain your own `.context/migrations.md` to track applied updates.

---

## Contributing Back

If you improve the Global Standards:

1. Fork [github.com/iamruinous/nix-config](https://github.com/iamruinous/nix-config)
2. Update files in `.context/global/`
3. Create a PR with your improvements
