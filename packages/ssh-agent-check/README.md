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

Updates `SSH_AUTH_SOCK` in tmux's global environment and optionally refreshes a specific pane.

### Usage

```bash
# Update tmux environment (run from a new pane with valid SSH_AUTH_SOCK)
ssh-agent-refresh

# Also refresh a specific pane
ssh-agent-refresh --pane 0

# Refresh pane by ID
ssh-agent-refresh --pane %5

# Silent mode
ssh-agent-refresh --quiet --pane 1
```

### Options

- `-h, --help` - Show help message
- `-q, --quiet` - Suppress output messages
- `-p, --pane PANE` - Send refresh command to specified pane

### How It Works

1. Updates tmux's global environment with the current `SSH_AUTH_SOCK`
2. If `--pane` is specified, sends a refresh command to that pane (works with bash, zsh, and fish)

### Requirements

- Must be run from inside a tmux pane that has a valid `SSH_AUTH_SOCK`
- Typically run from a newly opened pane after reconnecting to a session

### Workflow

When you reconnect to a remote session and your SSH agent socket has changed:

```bash
# 1. Check if agent is broken in current pane
ssh-agent-check || echo "Agent not responding!"

# 2. Open a new tmux pane (it will have the correct SSH_AUTH_SOCK)
# Press: prefix + c (or your new pane shortcut)

# 3. From the new pane, update tmux's environment
ssh-agent-refresh

# 4. Optionally refresh your old pane (e.g., pane 0)
ssh-agent-refresh --pane 0

# 5. Switch back and verify
ssh-agent-check && echo "Agent is working!"
```

### Manual Refresh in Existing Panes

If you prefer to refresh a pane manually instead of using `--pane`:

```bash
# For bash/zsh
eval "$(tmux show-env -s)"

# For fish
set -gx SSH_AUTH_SOCK (tmux show-environment SSH_AUTH_SOCK | cut -d= -f2-)
```
