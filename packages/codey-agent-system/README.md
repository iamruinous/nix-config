# codey-agent-system

OpenCode agent configuration files including AGENTS.md, protocols, and skills.

## Purpose

Provides the Codey Agent System files for use with OpenCode CLI. This includes:

- **AGENTS.md** - Primary context beacon for OpenCode agents
- **protocols/** - Protocol definitions for agent behavior
- **skill/** - Skill definitions for specialized tasks

## Source

Files are fetched from the [codey-agent-system](https://forge.meskill.farm/iamruinous/codey-agent-system) repository releases.

## Installation

The package installs files to `$out/share/codey-agent-system/`:

```
$out/share/codey-agent-system/
├── AGENTS.md
├── protocols/
└── skill/
```

## Usage

This package is typically consumed by the `ruinous.ai-cli.opencode` home-manager module, which symlinks the files into OpenCode config directories.

To use directly:

```nix
home.packages = [ pkgs.codey-agent-system ];

# Files available at:
# ${pkgs.codey-agent-system}/share/codey-agent-system/AGENTS.md
# ${pkgs.codey-agent-system}/share/codey-agent-system/protocols/
# ${pkgs.codey-agent-system}/share/codey-agent-system/skill/
```

## Updating

To update to a new version:

1. Update the `version` in `default.nix`
2. Update the `sha256` hash:
   ```bash
   nix-prefetch-url --unpack "https://forge.meskill.farm/iamruinous/codey-agent-system/releases/download/v<VERSION>/codey-agent-system-<VERSION>.zip"
   ```

## Version

Current version: **0.11.0**

## License

MIT
