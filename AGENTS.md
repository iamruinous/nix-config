# NixOS Configuration - Agent Context

**Primary Interface:** [OpenCode](https://opencode.ai) with [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)  
**Orchestrator:** Sisyphus (Claude Opus 4.5)  
**Context Version:** 2025.01.02

---

## Quick Start

```bash
# Start OpenCode with Sisyphus orchestration
opencode

# Magic word for maximum performance
# Include "ultrawork" or "ulw" in your prompt
```

**Single Source of Truth:** [.context/index.md](.context/index.md)

---

## Project Overview

NixOS configuration repository managing **24 hosts** across NixOS and Darwin (macOS) using the [blueprint](https://github.com/numtide/blueprint) flake pattern.

### Key Commands

| Action | Command |
|--------|---------|
| **NixOS Switch** | `nixos-rebuild switch --flake .#<hostname>` |
| **Darwin Switch** | `darwin-rebuild switch --flake .#<hostname>` |
| **Remote Deploy** | `make remote-rebuild remotehost=<hostname>` |
| **Dry Build** | `make remote-dry-build remotehost=<hostname>` |
| **Package Build** | `nix build .#<package-name>` |

### Directory Structure

```
.
├── hosts/           # Per-host configurations
├── modules/         # Reusable NixOS/Darwin/Home modules
├── packages/        # Custom Nix packages
├── secrets/         # Encrypted secrets (agenix)
├── users/           # User configurations
├── devshells/       # Development shells
├── .context/        # AI agent context (SSOT)
└── .claude/         # oh-my-opencode agent definitions
```

---

## oh-my-opencode Agent System

### Sisyphus: The Orchestrator

Sisyphus is the primary agent - a powerful orchestrator that:
- Plans and breaks down complex tasks into atomic steps
- Delegates to specialized agents (background or foreground)
- Manages parallel execution for maximum throughput
- Uses todo tracking to ensure task completion

**Philosophy:** "LLM Agents can write code as brilliant as ours and work just as excellently—if you give them great tools and solid teammates."

### Built-in Agents (oh-my-opencode)

| Agent | Model | Purpose |
|-------|-------|---------|
| **oracle** | GPT 5.2 | Architecture, debugging, strategy |
| **librarian** | Claude Sonnet 4.5 | Docs, OSS implementations, codebase research |
| **explore** | Grok Code | Fast codebase exploration (contextual grep) |
| **frontend-ui-ux-engineer** | Gemini 3 Pro | UI/UX development |
| **document-writer** | Gemini 3 Flash | Technical documentation |
| **multimodal-looker** | Gemini 3 Flash | PDF/image/diagram analysis |

### Project-Specific Agents (Custom)

Defined in `.claude/agents/` for oh-my-opencode compatibility:

| Agent | Purpose | Triggers |
|-------|---------|----------|
| **agenix** | Secrets management (.age files) | encrypt, rekey, secrets |
| **cfnix** | Cloudflare DNS & Tunnels | DNS, tunnel, cloudflare |
| **containnix** | Docker/OCI container deployment | container, docker, service |
| **nix-packager** | Nix package creation | package, derivation |

---

## Agent Delegation Matrix

### When to Delegate

| Task Category | Primary Agent | Also Involves |
|---------------|---------------|---------------|
| **Secrets** | | |
| Encrypt/Edit `.age` files | `agenix` | - |
| Rekey secrets | `agenix` | - |
| Docker env secrets | `agenix` | `containnix` (context) |
| **Containers** | | |
| Deploy new container | `containnix` | `agenix` (secrets), `cfnix` (DNS) |
| Update Caddy config | `containnix` | `agenix` (if encrypted) |
| Create database | `containnix` | - |
| **Networking** | | |
| Manage DNS records | `cfnix` | - |
| Create Cloudflare Tunnel | `cfnix` | `agenix` (creds), `containnix` (service) |
| **Packages** | | |
| Create new package | `nix-packager` | - |
| Fix build errors | `nix-packager` | `oracle` (strategy) |
| **Architecture** | | |
| Design decisions | `oracle` | - |
| Code review | `oracle` | - |
| Refactor modules | Sisyphus | `explore` (discovery) |
| **Documentation** | | |
| README updates | `document-writer` | - |
| API docs | `document-writer` | - |
| **Frontend** | | |
| Visual/UI changes | `frontend-ui-ux-engineer` | - |
| Logic in frontend files | Sisyphus (direct) | - |

### Delegation Prompt Structure

When delegating, include ALL 7 sections:

```
1. TASK: Atomic, specific goal
2. EXPECTED OUTCOME: Concrete deliverables with success criteria
3. REQUIRED SKILLS: Which skill to invoke
4. REQUIRED TOOLS: Explicit tool whitelist
5. MUST DO: Exhaustive requirements
6. MUST NOT DO: Forbidden actions
7. CONTEXT: File paths, existing patterns, constraints
```

---

## Background Tasks & Parallel Execution

### Fire Agents in Parallel (DEFAULT)

```typescript
// Launch exploration agents in background
background_task(agent="explore", prompt="Find auth patterns in codebase...")
background_task(agent="librarian", prompt="Find JWT best practices in docs...")

// Continue working immediately
// Collect results when needed: background_output(task_id="...")
```

### When to Use Background Tasks

- **Exploration** - searching codebase patterns
- **Research** - looking up documentation
- **Independent work** - frontend while working on backend
- **Parallel debugging** - multiple approaches simultaneously

---

## Critical Workflows

### Secrets Management (agenix)

**CRITICAL:** Never commit unencrypted secrets.

```bash
# Before working with secrets - USER must run:
agenix-helper unlock

# View encrypted file
agenix view /path/to/file.age

# Create new encrypted file
agenix edit -i input.txt output.age

# Update existing encrypted file
agenix view file.age > /tmp/temp.txt
# ... edit /tmp/temp.txt ...
rm file.age
agenix edit -i /tmp/temp.txt file.age
rm /tmp/temp.txt
agenix rekey -a

# When done - remind user to run:
agenix-helper lock
```

### Container Deployment (containnix)

1. Define container in `hosts/<hostname>/containers.nix`
2. Create encrypted env file if needed (delegate to `agenix`)
3. Create DNS record (delegate to `cfnix`)
4. Update Caddyfile for reverse proxy (delegate to `agenix` if encrypted)
5. Verify: `make remote-dry-build remotehost=<hostname>`

### Package Creation (nix-packager)

**Preferred pattern:** External shell scripts with `substitute`

```
packages/<name>/
├── default.nix      # stdenv.mkDerivation + substitute
├── <name>.sh        # Actual shell script
└── README.md        # Documentation
```

See `.context/project/architecture.md` for full template.

---

## Git Workflow

1. **Branch:** Create feature branch (`feat/`, `fix/`)
2. **Draft PR:** Create early for tracking
3. **Verify:** Run `make remote-dry-build remotehost=<target>`
4. **Sign:** GPG sign all commits
5. **PR:** Create with meaningful title and description

---

## Verification Protocol

### Before Marking Task Complete

- [ ] `lsp_diagnostics` clean on changed files
- [ ] Build passes: `make remote-dry-build remotehost=<target>`
- [ ] Tests pass (if applicable)
- [ ] All todos marked complete

### After 3 Failed Fix Attempts

1. **STOP** further edits
2. **REVERT** to last working state
3. **DOCUMENT** what failed
4. **CONSULT** Oracle
5. If Oracle fails → **ASK USER**

---

## Context System

### File Hierarchy

| Path | Purpose |
|------|---------|
| `AGENTS.md` | **Primary** - oh-my-opencode context (this file) |
| `.context/index.md` | Single source of truth index |
| `.context/global/` | Shared standards & protocols |
| `.context/project/` | Project-specific configuration |
| `.claude/agents/` | Custom agent definitions (oh-my-opencode loads these) |
| `.claude/commands/` | Slash commands |
| `GEMINI.md` | Secondary - Gemini CLI memory |
| `CLAUDE.md` | Secondary - Claude CLI memory |

### Updating Context

When you learn something that should be shared:

1. Update appropriate file in `.context/`
2. If new file created, update `.context/index.md`
3. Do NOT edit below `<!-- CONTEXT_BOOTSTRAP_START -->` in beacon files

---

## Common Recipes

### Create PostgreSQL Database

See `.context/project/recipes/create-db.md` or use slash command:
```
/create-db-<host>  # e.g., /create-db-monolith
```

### Create Raspberry Pi Host

See `.context/project/recipes/create-pi-host.md` or use slash command:
```
/create-pi-host
```

---

## Hard Constraints (NEVER Violate)

| Constraint | Action |
|------------|--------|
| Frontend VISUAL changes | ALWAYS delegate to `frontend-ui-ux-engineer` |
| Type error suppression | NEVER use `as any`, `@ts-ignore` |
| Commit without request | NEVER |
| Speculate about unread code | NEVER |
| Unencrypted secrets | NEVER commit |
| Leave code broken after failures | NEVER |

---

## MCP Servers Available

oh-my-opencode provides these MCPs by default:

| MCP | Purpose |
|-----|---------|
| **context7** | Official library documentation |
| **websearch_exa** | Real-time web search |
| **grep_app** | GitHub code search |
| **nixos** | NixOS/Home Manager/Darwin options search |
| **postgres-*** | Database introspection & queries |

---

## Getting Help

```bash
# Ask Oracle for architecture/strategy
Ask @oracle to review this design

# Ask Librarian for documentation/examples  
Ask @librarian how this library works

# Fast codebase search
Ask @explore where this pattern is used
```

**Remember:** When in doubt, `ultrawork` in your prompt activates maximum agent orchestration.
