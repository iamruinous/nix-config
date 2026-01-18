---
name: repo-onboarding
description: Transform any repository into an LLM-optimized, persona-connected workspace
compatibility: Requires git
metadata:
  author: ruinous.ai
  version: "1.0"
---

# Repo Onboarding

> Transform any repository into an LLM-optimized, persona-connected workspace.

**Purpose:** Connect a repository to the ruinous.ai agent ecosystem with proper tiered context loading and persona/SME ownership.

## Overview

This skill transforms repositories to be:
1. **LLM-friendly** - llms.txt index for fast context loading
2. **Persona-connected** - Owned by a specific SME/persona from agents.ruinous.ai
3. **Token-efficient** - Tiered loading instead of monolithic context
4. **oMo-native** - Optimized for oh-my-opencode + Sisyphus orchestration

## Prerequisites

Before running this skill:

1. **Identify the owning persona/SME** from [agents.ruinous.ai](https://agents.ruinous.ai):
   - NIXEY → Infrastructure/NixOS repos
   - NATEY → n8n/workflow repos
   - MESSY → Family/personal assistant repos
   - NEWSY → News/content repos
   - LIBBY → Documentation/writing repos

2. **Understand the repo's domain** - What decisions does this repo require?

3. **Identify existing context** - README.md, docs/, existing AGENTS.md

## Transformation Steps

### Step 1: Create llms.txt

Create `llms.txt` at repo root following [llmstxt.org](https://llmstxt.org/) spec:

```markdown
# <repo-name>

> One-line description. <PERSONA> is the SME.

<2-3 sentence expansion of what this repo does and who owns it.>

## Primary Context

- [<PERSONA> SME](https://agents.ruinous.ai/smes/<persona>/): Domain specialist
- [AGENTS.md](AGENTS.md): Local project context
- [Ruinous Agents](https://agents.ruinous.ai/llms.txt): Global ecosystem

## Repository Structure

<Brief tree showing key directories>

## Domain Reference

<Tables/lists of key domain concepts - hosts, services, workflows, etc.>

## Skills/Commands

<Available automation>

## Quick Start

<Essential commands to work with this repo>

## Related

- Links to persona docs
- Links to related repos
- Links to oh-my-opencode
```

**Key principles:**
- Front-load the most important context
- Use tables for structured data (scannable)
- Link to detail pages, don't duplicate
- Include runnable commands

### Step 2: Create/Rewrite AGENTS.md

Slim down to ~80-120 lines, structured as:

```markdown
# <repo-name>

> One-line description.

**LLM Context:** [llms.txt](llms.txt) | **Full Docs:** [agents.ruinous.ai](https://agents.ruinous.ai)

---

## <PERSONA> - <Role> SME

This repository is the domain of **[<PERSONA>](https://agents.ruinous.ai/smes/<persona>/)**.

**<PERSONA> provides:** <what expertise>
**Sisyphus executes:** Via oh-my-opencode orchestration

### Specialized Agents (if any)

| Agent | Domain | Triggers |
|-------|--------|----------|
| ... | ... | ... |

---

## Tiered Context Loading

| Need | Load |
|------|------|
| LLM-friendly overview | [llms.txt](llms.txt) |
| Full <PERSONA> expertise | [agents.ruinous.ai/smes/<persona>](url) |
| <domain detail> | [path/to/detail.md](path) |

---

## Quick Reference

<Most essential info for common tasks - 20-30 lines max>

---

## Skills

| Skill | Purpose |
|-------|---------|
| `/skill-name` | Description |

---

## Verification Checklist

Before completing any task:

- [ ] <verification step 1>
- [ ] <verification step 2>

---

## Related

- Links to ecosystem docs
```

### Step 3: Create Domain-Specific READMEs

For each major domain area, create a focused README:

```
secrets/README.md      # If repo has secrets
docs/NETWORKS.md       # If repo has network/infra concepts
docs/README.md         # If repo has generated docs
workflows/README.md    # If repo has workflows
api/README.md          # If repo has API definitions
etc.
```

**Common domain docs:**
- `secrets/README.md` - Encryption patterns, key management
- `docs/NETWORKS.md` - VLANs, DNS domains, network topology
- `workflows/README.md` - Automation workflows, triggers
- `api/README.md` - API endpoints, authentication

Each should be:
- **Condensed** - Essential patterns only
- **Actionable** - Commands and examples
- **Linked** - Reference full docs elsewhere

### Step 4: Set Up .opencode/ Structure

```
.opencode/
├── oh-my-opencode.jsonc   # oMo configuration
├── skill/                 # Project-specific skills (agentskills.io format)
│   └── <skill-name>/
│       └── SKILL.md
└── (agents/)              # Only if project-specific agents needed
```

**oh-my-opencode.jsonc template:**

```jsonc
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",

  // Project: <org>/<repo>
  // <One-line description>

  "agents": {
    "oracle": {
      "prompt_append": "This is a <domain> repository. <domain-specific guidance>"
    },
    "librarian": {
      "prompt_append": "For <domain> questions, search <relevant sources>."
    },
    "explore": {
      "prompt_append": "Key directories: <list>. Look for patterns in <where>."
    }
  },

  "disabled_hooks": [],
  "disabled_mcps": [],

  "ralph_loop": {
    "enabled": true,
    "default_max_iterations": 10
  },

  "claude_code": {
    "mcp": true,
    "commands": true,
    "skills": true,
    "agents": true,
    "hooks": true
  }
}
```

### Step 5: Migrate Existing .claude/ (if present)

If repo has `.claude/` directory from Claude Code:

1. Move commands → `.opencode/skill/<name>/SKILL.md`
2. Move agents → `.opencode/agents/` (if project-specific)
3. Add deprecation notice to `.claude/README.md`:

```markdown
# Deprecated

This directory is deprecated. Use `.opencode/` instead.

- Skills: `.opencode/skill/`
- Agents: `.opencode/agents/`
- Config: `.opencode/oh-my-opencode.jsonc`
```

### Step 6: Update README.md

Add AI agent section to main README:

```markdown
## AI Agent Workflow

This repository uses **[OpenCode](https://opencode.ai)** with **[oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)**.

**SME:** [<PERSONA>](https://agents.ruinous.ai/smes/<persona>/) - <domain> specialist

For agent context, see [AGENTS.md](AGENTS.md) or [llms.txt](llms.txt).
```

## Checklist

Use this checklist when onboarding a repo:

- [ ] Identify owning persona/SME
- [ ] Create `llms.txt` with LLM-friendly index
- [ ] Rewrite `AGENTS.md` (slim, tiered loading)
- [ ] Create domain-specific READMEs as needed
- [ ] Set up `.opencode/` structure
- [ ] Configure `oh-my-opencode.jsonc`
- [ ] Migrate `.claude/` if present (with deprecation)
- [ ] Update main `README.md` with agent section
- [ ] Verify all links work
- [ ] Test with `opencode` to ensure context loads properly

## Examples

### Infrastructure Repo (NIXEY)

```
nix-config/
├── AGENTS.md          # Points to NIXEY, tiered loading
├── llms.txt           # Host inventory, networks, commands
├── hosts/README.md    # Detailed host specs
├── secrets/README.md  # Agenix patterns
└── .opencode/
    ├── oh-my-opencode.jsonc
    └── skill/
        ├── deploy-container/SKILL.md
        └── create-db/SKILL.md
```

### Workflow Repo (NATEY)

```
n8n-workflows/
├── AGENTS.md          # Points to NATEY, tiered loading
├── llms.txt           # Workflow inventory, triggers, patterns
├── workflows/README.md # Workflow catalog
└── .opencode/
    ├── oh-my-opencode.jsonc
    └── skill/
        └── create-workflow/SKILL.md
```

### Documentation Repo (LIBBY)

```
docs-site/
├── AGENTS.md          # Points to LIBBY, tiered loading
├── llms.txt           # Content structure, style guide
├── docs/README.md     # Content organization
└── .opencode/
    ├── oh-my-opencode.jsonc
    └── skill/
        └── write-guide/SKILL.md
```

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Duplicate persona definition locally | Link to agents.ruinous.ai |
| Put everything in AGENTS.md | Use tiered loading with focused READMEs |
| Create monolithic context files | Break into scannable, linked documents |
| Ignore existing structure | Enhance existing READMEs, don't replace |
| Skip llms.txt | It's the primary LLM entry point |

## Related

- [llmstxt.org](https://llmstxt.org/) - llms.txt specification
- [agentskills.io](https://agentskills.io/specification) - Skill specification
- [agents.ruinous.ai](https://agents.ruinous.ai/) - Persona/SME definitions
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) - Agent framework
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) - Documentation format
