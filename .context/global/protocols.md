# AI Agent Protocols (Global)

This document defines the standard operational protocols for the multi-agent system using **oh-my-opencode** with **Sisyphus** as the orchestrator.

## Primary Interface

**OpenCode with oh-my-opencode** is the primary AI agent interface.

- **Orchestrator:** Sisyphus (Claude Opus 4.5)
- **Magic Word:** `ultrawork` or `ulw` for maximum parallel agent performance
- **Context Beacon:** `AGENTS.md` in project root

### Alternative Interfaces
- Gemini CLI → `GEMINI.md`
- Claude CLI → `CLAUDE.md`

---

## Sisyphus Orchestration Model

Sisyphus operates as the central orchestrator, delegating to specialized agents for domain-specific tasks.

### Agent Categories

| Category | Agents | Purpose |
|----------|--------|---------|
| **Orchestrator** | Sisyphus | Planning, delegation, coordination |
| **Built-in** | oracle, librarian, explore, frontend-ui-ux-engineer, document-writer, multimodal-looker | General-purpose specialists |
| **Project** | agenix, cfnix, containnix, nix-packager | Project-specific specialists |

### Built-in Agent Roles

| Agent | Model | Use When |
|-------|-------|----------|
| **oracle** | GPT 5.2 | Architecture decisions, debugging, strategy, code review |
| **librarian** | Claude Sonnet 4.5 | Documentation lookup, OSS examples, codebase research |
| **explore** | Grok Code | Fast codebase exploration, pattern matching |
| **frontend-ui-ux-engineer** | Gemini 3 Pro | Visual/UI changes (NOT logic) |
| **document-writer** | Gemini 3 Flash | README, API docs, technical writing |
| **multimodal-looker** | Gemini 3 Flash | PDF/image/diagram analysis |

---

## Usage Protocols

### 0. Initialization Phase (Mandatory)
At the start of any new session or task:
1.  **Read Context:** Check `AGENTS.md` for primary context
2.  **Check SSOT:** Reference `.context/index.md` for detailed information
3.  **Understand Scope:** Identify which agents may be needed

### 1. Planning Phase (Mandatory)
Before executing complex changes, Sisyphus **MUST** create a plan:
*   **Analyze:** Use tools to understand current state
*   **Create Todos:** Use `todowrite` tool to outline atomic steps
*   **Identify Delegation:** Note which specialist agents are needed
*   **Mark Progress:** Update todos as `in_progress` → `completed`

### 2. Delegation Protocol

#### Background Agents (Preferred for Exploration)
```typescript
// Fire parallel agents in background
background_task(agent="explore", prompt="Find auth patterns...")
background_task(agent="librarian", prompt="Find best practices for...")

// Continue working immediately
// Collect results when needed: background_output(task_id="...")
```

#### Foreground Agents (For Complex Tasks)
```typescript
// Use task() for complex work requiring full agent capabilities
task(agent="containnix", prompt="Deploy container with full context...")
```

#### Delegation Prompt Structure (MANDATORY)
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

### 3. Verification Protocol

Before marking any task complete:
- [ ] `lsp_diagnostics` clean on changed files
- [ ] Build passes (if applicable)
- [ ] All todos marked complete

### 4. Knowledge Management
*   **Read:** Always check `.context/` first
*   **Update:** Modify `.context/` files for shared knowledge
*   **Index:** Update `.context/index.md` when creating new files
*   **Agents:** Update `.claude/agents/` for agent-specific instructions

---

## Failure Recovery

### After 3 Failed Fix Attempts
1. **STOP** all further edits immediately
2. **REVERT** to last known working state
3. **DOCUMENT** what was attempted and what failed
4. **CONSULT** Oracle with full failure context
5. If Oracle cannot resolve → **ASK USER**

### Escalation Path
1. Retry with more context
2. Consult Oracle for strategy
3. Ask user for intervention

---

## Hard Constraints (NEVER Violate)

| Constraint | Action |
|------------|--------|
| Frontend VISUAL changes | ALWAYS delegate to `frontend-ui-ux-engineer` |
| Type error suppression | NEVER use `as any`, `@ts-ignore` |
| Commit without request | NEVER |
| Speculate about unread code | NEVER |
| Leave code broken | NEVER |

---

## Context Bootstrapping (Memory Beacon)

For alternative interfaces (Gemini, Claude CLI), beacon files maintain context:

1.  **Beacon Files:** `GEMINI.md`, `CLAUDE.md` serve as working memory
2.  **Structure:** 
    - **Top (Mutable):** Agent memories and active task tracking
    - **Divider:** `<!-- CONTEXT_BOOTSTRAP_START -->`
    - **Bottom (Immutable):** Bootstrapped context summary
3.  **Primary Reference:** Always point to `AGENTS.md` and `.context/index.md`
