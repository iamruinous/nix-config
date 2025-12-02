# ssh-agent-check

SSH agent utilities for NixOS: check availability and refresh across tmux panes.

## Overview

This package provides two commands:

- **`ssh-agent-check`** - Fast, cached SSH agent availability checker
- **`ssh-agent-refresh`** - Refresh SSH_AUTH_SOCK across all tmux panes

## Usage

```bash
ssh-agent-check
echo $?  # 0 = agent working, 1 = agent not responding
```

### In Shell Scripts

```bash
if ssh-agent-check; then
  echo "SSH agent is available"
else
  echo "SSH agent is not responding"
fi
```

### In Starship

```toml
[custom.ssh_agent]
when = "! ssh-agent-check"
format = "[$symbol]($style)"
symbol = "󰌆"
style = "bold red"
```

### In Fish Shell

```fish
if ssh-agent-check
  echo "Agent working"
else
  echo "Agent not responding"
end
```

## Exit Codes

- `0` - SSH agent is working (reachable, with or without keys)
- `1` - SSH agent is not responding or SSH_AUTH_SOCK not set

## How It Works

### Initial Check

1. Checks if `SSH_AUTH_SOCK` is set
2. If not set, returns exit code 1
3. Runs `ssh-add -L` to test agent responsiveness
4. Caches the result with the current SSH_AUTH_SOCK value

### Cached Checks

1. Reads cache file (if exists)
2. If SSH_AUTH_SOCK matches cached value, returns cached result instantly
3. If SSH_AUTH_SOCK changed, runs fresh check and updates cache

### Cache Details

- **Location**: `$XDG_RUNTIME_DIR/ssh-agent-check-cache-$$` (or `/tmp` if XDG not set)
- **Format**: `<SSH_AUTH_SOCK_PATH> <RESULT>`
- **Scope**: Per shell session (uses `$$` in filename)
- **Invalidation**: Automatic when SSH_AUTH_SOCK changes

## Performance

- **First check**: ~10-50ms (runs ssh-add -L)
- **Cached checks**: <1ms (file read only)
- **Cache hit rate**: ~99% in typical usage (starship prompts)

## Integration

This package is used by:
- `modules/home/default/fish.nix` - Shell startup warning
- `modules/home/default/starship.nix` - Prompt indicator

## Background

Created to solve the problem of detecting SSH agent failures that occur during a shell session, not just at startup. The caching mechanism ensures starship prompts remain fast while still detecting agent changes.

## ssh-add Exit Codes Reference

- `0` - Agent has identities (working)
- `1` - Agent reachable but no identities (working)
- `2` - Cannot contact agent (broken)

This script treats exit codes 0 and 1 as "working" (returns 0), and exit code 2 as "broken" (returns 1).

---

## ssh-agent-refresh

Refreshes `SSH_AUTH_SOCK` in tmux's environment and optionally across all panes.

### Usage

```bash
# Update tmux environment only (recommended for keybindings)
ssh-agent-refresh --current

# Refresh all tmux panes (works with bash, zsh, and fish)
ssh-agent-refresh

# Preview what would be refreshed (dry run)
ssh-agent-refresh --dry-run

# Silent mode for scripts
ssh-agent-refresh --quiet
```

### Options

- `-h, --help` - Show help message
- `-q, --quiet` - Suppress output messages
- `-n, --dry-run` - Show what would be done without executing
- `-c, --current` - Only update tmux environment (don't send commands to panes)

### How It Works

1. Updates tmux's stored environment with the current `SSH_AUTH_SOCK`
2. With `--current`: Stops here (new panes inherit automatically)
3. Without `--current`: Sends a refresh command to every tmux pane that works with bash, zsh, and fish

### Requirements

- Must be run inside a tmux session (or have `TMUX_PANE` set for `run-shell`)
- `SSH_AUTH_SOCK` must be set and point to a valid socket

### Tmux Keybinding

The recommended way to use this is via a tmux keybinding with `--current`:

```tmux
# In tmux.conf - prefix + S to refresh
bind S run-shell "ssh-agent-refresh --quiet --current"
```

This updates tmux's environment so new panes get the correct `SSH_AUTH_SOCK`.
Existing panes can manually refresh with: `eval "$(tmux show-env -s)"`

### Example Workflow

When you reconnect to a remote session and your SSH agent socket has changed:

```bash
# Check if agent is broken
ssh-agent-check || echo "Agent not responding!"

# Option 1: Use tmux keybinding (prefix + S) to update tmux env

# Option 2: Refresh all panes programmatically
ssh-agent-refresh

# Verify it's working now
ssh-agent-check && echo "Agent is working!"
```

### Manual Refresh in Existing Panes

If you used `--current` and need to refresh an existing pane:

```bash
# For bash/zsh
eval "$(tmux show-env -s)"

# For fish
eval (tmux show-environment SSH_AUTH_SOCK | string replace '=' ' '); set -gx SSH_AUTH_SOCK $SSH_AUTH_SOCK
```
