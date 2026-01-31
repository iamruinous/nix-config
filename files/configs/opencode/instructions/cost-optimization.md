# Cost-Optimization Delegation Guidelines

## Overview

Before executing any task directly on your current model (likely opus), evaluate whether it can be delegated to a cheaper model via the oh-my-opencode category system.

**Default bias:** Delegate to `quick` unless reasoning complexity requires your capabilities.

## Decision Matrix

| Task Signal | Category | Model Tier | Rationale |
|-------------|----------|------------|-----------|
| Issue/PR creation | `quick` | haiku | Templated text generation |
| Single-file edit with clear spec | `quick` | haiku | Execution, not reasoning |
| Documentation/README updates | `writing` | flash | Prose generation |
| Config changes following patterns | `quick` | haiku | Pattern matching |
| Commit message generation | `quick` | haiku | Summarization |
| Multi-file exploration needed | `deep` | sonnet | Research required |
| Architecture decisions | `ultrabrain` | opus | Complex reasoning |
| Debugging (2+ failed attempts) | `ultrabrain` | opus | Deep analysis |
| Multi-source synthesis | Keep on current | opus | Your strength |

## When to Delegate

Ask yourself:

> "Can a haiku-class model complete this task with a clear, explicit prompt?"

If **yes** → Delegate to `quick` category with exhaustive instructions.

If **no** (requires exploration, debugging, architecture reasoning) → Execute directly.

## Delegation Prompt Requirements

When delegating to `quick`, your prompt MUST include:

1. **Exact file paths** to modify
2. **Specific changes** (not "improve" or "fix")
3. **Expected output** format
4. **MUST NOT** constraints

Example:
```
delegate_task(
  category="quick",
  load_skills=[],
  prompt="""
  Create GitHub issue for nix-config repository.
  
  TASK: Create issue titled "Add dark mode toggle"
  
  BODY:
  - Summary: Add dark mode toggle to settings page
  - Acceptance criteria: Toggle persists across sessions
  
  MUST DO: Use mcp_github_issue_write tool
  MUST NOT: Add labels or assignees
  """
)
```

## Cost Awareness

| Model | Relative Cost | Use For |
|-------|---------------|---------|
| haiku | $ | Execution tasks |
| flash | $ | Writing tasks |
| sonnet | $$ | Research/exploration |
| opus | $$$ | Complex reasoning |

**Every opus token spent on a haiku-capable task is waste.**
