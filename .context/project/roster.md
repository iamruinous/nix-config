# Agent Roster & Delegation (Project Specific)

## oh-my-opencode Agent System

This project uses **oh-my-opencode** with **Sisyphus** as the orchestrator. Agents are organized into two categories:

### Built-in Agents (oh-my-opencode)

| Agent | Model | Purpose |
|-------|-------|---------|
| **oracle** | GPT 5.2 | Architecture, debugging, strategy, code review |
| **librarian** | Claude Sonnet 4.5 | Documentation, OSS examples, codebase research |
| **explore** | Grok Code | Fast codebase exploration (contextual grep) |
| **frontend-ui-ux-engineer** | Gemini 3 Pro | Visual/UI development |
| **document-writer** | Gemini 3 Flash | Technical documentation |
| **multimodal-looker** | Gemini 3 Flash | PDF/image/diagram analysis |

### Project-Specific Agents

Defined in `.claude/agents/` for oh-my-opencode compatibility.

| Agent | Purpose | Location |
|-------|---------|----------|
| **agenix** | Secrets management (.age files) | `.claude/agents/agenix.md` |
| **cfnix** | Cloudflare DNS & Tunnels | `.claude/agents/cfnix.md` |
| **containnix** | Container orchestration | `.claude/agents/containnix.md` |
| **nix-packager** | Nix package creation | `.claude/agents/nix-packager.md` |

---

## Task Delegation Matrix

### When to Use Built-in Agents

| Task | Agent | Execution |
|------|-------|-----------|
| Architecture decisions | `oracle` | Foreground |
| Code review | `oracle` | Foreground |
| Find codebase patterns | `explore` | Background (parallel) |
| Lookup documentation | `librarian` | Background (parallel) |
| OSS implementation examples | `librarian` | Background (parallel) |
| Visual/UI changes | `frontend-ui-ux-engineer` | Foreground |
| Write documentation | `document-writer` | Foreground |
| Analyze images/PDFs | `multimodal-looker` | Foreground |

### When to Use Project Agents

| Task Category | Primary Agent | Also Involves |
|---------------|---------------|---------------|
| **Secrets Management** | | |
| Encrypt/Edit `.age` files | `agenix` | - |
| Rekey secrets | `agenix` | - |
| Create Docker env files | `agenix` | `containnix` (context) |
| **Infrastructure** | | |
| Deploy new container | `containnix` | `agenix` (secrets), `cfnix` (DNS) |
| Update Caddy config | `containnix` | `agenix` (if encrypted), `cfnix` (DNS) |
| Create database | `containnix` (via recipes) | - |
| **Networking** | | |
| Manage DNS records | `cfnix` | - |
| Create Cloudflare Tunnels | `cfnix` | `agenix` (creds), `containnix` (service) |
| **Development** | | |
| Create new package | `nix-packager` | - |
| Fix build errors | `nix-packager` | `oracle` (strategy) |

---

## Parallel Execution Patterns

### Exploration Pattern
```typescript
// Fire multiple exploration agents in parallel
background_task(agent="explore", prompt="Find all container definitions...")
background_task(agent="explore", prompt="Find network configurations...")
background_task(agent="librarian", prompt="Find Docker compose best practices...")

// Continue working, collect results when needed
```

### Research + Implementation Pattern
```typescript
// Research in background while planning
background_task(agent="librarian", prompt="Find agenix secret patterns...")

// Start implementation
// ... work on task ...

// Collect research when ready to apply
const research = await background_output(task_id="...")
```

---

## Agent Invocation

### Explicit Invocation
```
Ask @oracle to review this architecture
Ask @librarian how this library works
Ask @explore where this pattern is used
```

### Delegation via Task Tool
```typescript
// For project-specific agents
task(agent="agenix", prompt="Encrypt new secrets following delegation structure...")
task(agent="containnix", prompt="Deploy new container with full context...")
```

---

## Common Multi-Agent Workflows

### Deploy New Service
1. **explore** - Find existing patterns (background)
2. **containnix** - Create container definition
3. **agenix** - Create encrypted env file
4. **cfnix** - Create DNS record
5. **containnix** - Update Caddyfile

### Debug Build Failure
1. **explore** - Find related code (background)
2. **librarian** - Find similar issues (background)
3. **Sisyphus** - Analyze and attempt fix
4. **oracle** - Consult if 2+ attempts fail
