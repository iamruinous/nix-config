# ruinous-login-hub

SSH login hub with TUI menu for tmux/tmuxp session management.

## Overview

A terminal user interface (TUI) application that presents an interactive menu on SSH login, allowing users to quickly attach to tmux sessions or load tmuxp configurations.

## Features

- **Interactive Menu** - Clean TUI with numbered options
- **Hub Session** - Attach to or create a persistent `hub` tmux session
- **tmuxp Discovery** - Automatically discovers and lists tmuxp session configurations
- **Plain Shell** - Option to bypass and drop to a regular shell
- **Bypass Mechanism** - Environment variable to skip the menu entirely
- **Optional Banner** - ASCII art banner using `toilet` (if available)

## Usage

The login hub is typically configured as a login shell or executed automatically on SSH connection. When launched, it displays a menu with available options:

```
Welcome to ruinous.farm

1. Hub Session
2. tmuxp: development
3. tmuxp: monitoring
4. Plain Shell

Select an option (1-4):
```

### Menu Options

| Option | Description |
|--------|-------------|
| **Hub Session** | Attaches to the `hub` tmux session if it exists, otherwise creates it |
| **tmuxp: <name>** | Loads the specified tmuxp session configuration from `~/.config/tmuxp/<name>.json` |
| **Plain Shell** | Exits the menu and drops to a regular shell prompt |

### Bypass Mechanism

To skip the login hub menu and go directly to a shell, set the `BYPASS_LOGIN_HUB` environment variable:

```bash
# Skip the menu for this session
BYPASS_LOGIN_HUB=1 ssh user@host

# Or set it in your SSH config
Host myhost
  SetEnv BYPASS_LOGIN_HUB=1
```

When bypassed, the login hub exits immediately without displaying the menu.

## tmuxp Discovery

The login hub automatically discovers tmuxp session configurations by scanning `~/.config/tmuxp/` for `.json` files. Each discovered configuration appears as a menu option.

**Discovery behavior:**
- Scans `~/.config/tmuxp/*.json`
- Extracts session name from filename (e.g., `development.json` → "development")
- Displays as "tmuxp: <name>" in the menu
- If no tmuxp configs found, only Hub Session and Plain Shell options are shown

## Dependencies

| Dependency | Required | Purpose |
|------------|----------|---------|
| **tmux** | Yes | Session management |
| **tmuxp** | Optional | Loading tmuxp configurations |
| **toilet** | Optional | ASCII art banner |

## Integration

This package is typically used with:
- SSH login shells
- Home Manager shell configuration
- Remote server access workflows

## Background

Created to provide a consistent, user-friendly entry point for SSH sessions, making it easy to jump into the right tmux session or tmuxp environment without memorizing commands.

### Filtering

Press `/` to activate filter mode and type to narrow down the list. For example:
- Type `kim` to show only sessions matching "kimaki"
- Type `hub` to quickly find the Hub Session
- Press `Esc` to clear the filter

The filter searches across session names and descriptions.
