# Documentation

> Infrastructure documentation for nix-config. Built with Material for MkDocs.

## Contents

| Document | Purpose |
|----------|---------|
| [NETWORKS.md](NETWORKS.md) | VLANs, DNS domains, network topology |

## N0FRILLS Theme System

Complete documentation for the N0FRILLS design system implementation across all CLI tools.

### Implementation Guides

| Tool | Guide | What You'll Learn |
|------|-------|-------------------|
| **Gemini CLI** | [guides/gemini-theme-guide.md](guides/gemini-theme-guide.md) | N0FRILLS theme integration for AI CLI |
| **Neovim** | [guides/neovim-theme-guide.md](guides/neovim-theme-guide.md) | Custom colorscheme implementation |
| **OpenCode** | [guides/opencode-theme-guide.md](guides/opencode-theme-guide.md) | AI coding assistant theme files |
| **Starship** | [guides/starship-theme-guide.md](guides/starship-theme-guide.md) | Theme compositor with 4 colorways × 3 styles |
| **tmux** | [guides/tmux-theme-guide.md](guides/tmux-theme-guide.md) | Terminal multiplexer theming patterns |
| **WezTerm** | [guides/wezterm-theme-guide.md](guides/wezterm-theme-guide.md) | Terminal emulator color schemes |
| **xplr** | [guides/xplr-theme-guide.md](guides/xplr-theme-guide.md) | File manager theming system |

### Research & Design

| Document | What You'll Learn | Read If... |
|----------|-------------------|------------|
| [plans/starship-n0frills-theme.md](plans/starship-n0frills-theme.md) | Theme compositor architecture and implementation plan | You're understanding the Starship design |
| [research/neovim-theming.md](research/neovim-theming.md) | Neovim colorscheme patterns and LSP integration | You're extending Neovim themes |
| [research/opencode-theming.md](research/opencode-theming.md) | OpenCode theme structure and token scopes | You're creating OpenCode themes |
| [research/tmux-theming.md](research/tmux-theming.md) | Comprehensive tmux theming research (all UI elements) | You're customizing tmux appearance |
| [research/tmux-theming-extended.md](research/tmux-theming-extended.md) | Extended tmux patterns (messages, copy mode, popups) | You need advanced tmux styling |
| [research/wezterm-theming.md](research/wezterm-theming.md) | WezTerm color scheme formats and integration | You're creating WezTerm themes |
| [research/xplr-theming.md](research/xplr-theming.md) | xplr theming capabilities and layout system | You're customizing xplr |

### Philosophy & Colorways

**N0FRILLS Design Principles:**
- **No Waste** - Functional information only, remove decoration
- **Visual Stability** - Consistent positioning reduces cognitive load
- **Direct Voice** - Bracket notation `[>]` `[~]` over Unicode glyphs
- **Absolute Consistency** - Shared colorways across entire CLI ecosystem

**Available Colorways:**
- **classic** - Monochrome brutalism (white/gray)
- **ruin** - High-energy contrast (magenta/cyan)
- **siege** - Professional depth (purple/teal)
- **ghost** - Warm minimalism (white/amber)

## Format

All documentation uses **Material for MkDocs** conventions:
- Markdown with admonitions, tabs, and code blocks
- Tables for structured data
- Mermaid diagrams where helpful

## Building Docs

If MkDocs is configured:

```bash
# Local preview
mkdocs serve

# Build static site
mkdocs build
```

## Related

- [AGENTS.md](../AGENTS.md) - Agent context entry point
- [llms.txt](../llms.txt) - LLM-friendly index
- [hosts/README.md](../hosts/README.md) - Host specifications
