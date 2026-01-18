# ruinagents-global

Nix package for ruinous.ai agents documentation (AGENTS.md, protocols, skills).

## Purpose

Provides Ruinagents Global files for use with OpenCode CLI. This includes:

- **AGENTS.md** - Primary context beacon for OpenCode agents
- **protocols/** - Protocol definitions for agent behavior
- **skill/** - Skill definitions for specialized tasks

## Source

Files are fetched from [ruinagents](https://forge.meskill.farm/iamruinous/ruinagents) repository releases.

## Installation

The package installs files to `$out/share/ruinagents-global/`:

```
$out/share/ruinagents-global/
├── AGENTS.md
├── protocols/
└── skill/
```

## Usage

This package is typically consumed by the `ruinous.ai-cli.opencode` home-manager module, which symlinks files into OpenCode config directories.

## Version

Current version: **0.5.1**

## License

MIT
