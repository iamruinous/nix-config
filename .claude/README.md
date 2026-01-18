# Deprecated

> **This directory is deprecated.** Use `.opencode/` instead.

The `.claude/` directory structure was used for Claude Code compatibility. The primary location for oh-my-opencode configuration is now `.opencode/`.

## Migration

| Old Location | New Location |
|--------------|--------------|
| `.claude/commands/` | `.opencode/skills/` |
| `.claude/agents/` | `.opencode/agents/` |

## Compatibility

Files in `.claude/` are still read by oh-my-opencode for backward compatibility via the `claude_code` configuration in `.opencode/oh-my-opencode.jsonc`.

New files should be added to `.opencode/` instead.

## Structure

```
.opencode/
├── oh-my-opencode.jsonc   # Primary configuration
├── skills/                # Workflow automation (formerly commands)
│   ├── automerge.md
│   ├── pr.md
│   ├── create-db-*.md
│   ├── create-pi-host.md
│   └── repo-onboarding.md
└── agents/                # Project-specific agents
    ├── agenix.md          # Secrets management
    ├── cfnix.md           # Cloudflare DNS/tunnels
    ├── containnix.md      # Container deployment
    └── nix-packager.md    # Nix package creation
```

## Context Loading

For LLM context, use:
- [llms.txt](../llms.txt) - LLM-friendly repo index
- [AGENTS.md](../AGENTS.md) - Minimal entry point with tiered loading
- [NIXEY SME](https://agents.ruinous.ai/smes/nixey/) - Full infrastructure expertise
