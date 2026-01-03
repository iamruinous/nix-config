# Multi-Agent Orchestration

**Status:** Implemented via [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)

## Current Implementation

This project uses **OpenCode with oh-my-opencode** as the primary AI agent interface, with **Sisyphus** (Claude Opus 4.5) as the orchestrator.

### Why oh-my-opencode?

oh-my-opencode implements the Hub-and-Spoke architecture described below, but with:
- **Built-in orchestration** - Sisyphus handles planning and delegation automatically
- **Curated agents** - Oracle, Librarian, Explore, and domain specialists
- **Background tasks** - True parallel execution without copy-pasting context
- **Claude Code compatibility** - Loads `.claude/agents/` and `.claude/commands/`
- **MCP integration** - Context7, Exa web search, grep.app code search

### Quick Start

```bash
# Start OpenCode with Sisyphus orchestration
opencode

# Magic word for maximum performance
# Include "ultrawork" or "ulw" in your prompt
```

See **[AGENTS.md](../../AGENTS.md)** for complete documentation.

---

## Original Planning Notes (Historical)

The following describes the architectural concepts that led to our current implementation.

### The Architecture: Hub-and-Spoke

Instead of maintaining multiple context windows across different AI tools, choose one **primary driver** (orchestrator) and treat others as tools the driver can invoke.

**Benefits:**
- **Zero Duplication:** Context maintained only in the Driver
- **Best-of-Breed:** Use the best model for each task type
- **Parallel Execution:** Background agents work simultaneously

### Agent Roles

| Role | Description | oh-my-opencode Agent |
|------|-------------|---------------------|
| **Manager** | Reasoning, planning, final code | Sisyphus (Claude Opus 4.5) |
| **Strategist** | Architecture, debugging | oracle (GPT 5.2) |
| **Librarian** | Large file search, docs | librarian (Claude Sonnet 4.5) |
| **Explorer** | Fast codebase navigation | explore (Grok Code) |
| **Specialist** | Domain-specific tasks | Custom agents in `.claude/agents/` |

### Unified Context Management

All context is managed through:
1. **AGENTS.md** - Primary context beacon for OpenCode
2. **.context/** - Single source of truth directory
3. **.claude/agents/** - Custom agent definitions
4. **.claude/commands/** - Slash commands

### Context Beacon Pattern

The `AGENTS.md` file in project root serves as the primary context source. Agents are primed to read this file first for project state, architecture pointers, and workflow instructions.

---

## Legacy Approaches (Superseded)

The following approaches were considered but superseded by oh-my-opencode:

### MCP Sub-Agent Pattern
Previously, we considered manually configuring MCP servers for each tool. oh-my-opencode handles this automatically with built-in MCPs.

### CLI Sub-Agent Pattern  
The "soft" integration via shell commands is now handled by oh-my-opencode's background task system, which provides proper async execution and result collection.

### Multiple Context Files
Instead of maintaining `CLAUDE.md`, `GEMINI.md`, and `AGENTS.md` separately, we now use `AGENTS.md` as primary with the others as secondary/legacy support.
