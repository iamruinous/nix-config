# 0p-cli

Op management CLI for isolated development sessions with worktree isolation, XDG directory separation, and tmux session management.

## Overview

`0p` is a CLI tool for managing **Ops** - isolated development sessions that provide:

- **Worktree isolation**: Each Op gets its own git worktree for parallel development
- **XDG directory separation**: Isolated agent configuration per Op
- **tmux session management**: Pre-configured sessions with 5 windows (logs, agent, editor, files, shell)
- **State persistence**: SQLite database tracks Op states and metadata

## Installation

### Using Nix

```nix
# In your home configuration
ruinous.op-cli.enable = true;
```

### Manual Installation

```bash
cd packages/ruinous-0p-cli
go build -o 0p .
cp 0p ~/bin/
```

## Quick Start

```bash
# Create a new Op
0p new my-feature --repo nix-config --deck chassis

# Attach to the Op (launches tmux session)
0p attach my-feature

# Do work... then suspend
0p suspend my-feature

# Resume later
0p resume my-feature

# Complete when done
0p complete my-feature
```

## Commands

### `0p new [op-id]`

Create a new Op with the specified ID.

**Flags:**
- `--repo, -r`: Repository name (required)
- `--deck, -d`: Deck name (required)
- `--mode, -m`: Op mode: interactive, autonomous, or exception (default: interactive)

**Example:**
```bash
0p new billing-fix --repo nix-config --deck chassis --mode interactive
```

### `0p list`

List all Ops with their current state, repository, deck, and mode.

### `0p status [op-id]`

Show detailed status of a specific Op.

### `0p attach [op-id]`

Attach to an Op's tmux session. Creates the session if it doesn't exist.

### `0p suspend [op-id]`

Suspend an active Op by detaching from its tmux session and updating state.

### `0p resume [op-id]`

Resume a suspended Op and attach to its tmux session.

### `0p complete [op-id]`

Complete an Op and clean up all resources. Prompts for confirmation and optionally merges the branch to main.

## Op Lifecycle

```
scheduled → active → suspended → completed
     ↓         ↓          ↓
   create    attach    resume
            suspend   complete
```

## Directory Structure

```
~/Projects/.ops/
└── <op-id>/
    └── <repo-name>/          # Git worktree

~/.config/opencode-<op-id>/   # XDG config
~/.local/share/opencode-<op-id>/  # XDG data
~/.local/state/opencode-<op-id>/  # XDG state
~/.cache/opencode-<op-id>/    # XDG cache

~/.config/tmuxp/<op-id>.json  # tmuxp session config
~/.local/share/0p/            # Database directory
    └── ops.db                # SQLite database
```

## Session Layout

Each Op gets a tmux session with 5 windows:

1. **logs**: `journalctl` for the Op (or message if no service)
2. **agent**: `opencode` with isolated XDG directories (focused window)
3. **editor**: `nvim .`
4. **files**: `xplr`
5. **shell**: `fish`

## Configuration

### Environment Variables

- `OP_DATA_DIR`: Override the default data directory (default: `~/.local/share/0p`)
- `XDG_CONFIG_HOME`: Used for config file location

### Config File

Create `~/.config/0p/config.yaml`:

```yaml
data_dir: /custom/path/to/data
```

## Development

### Running Tests

```bash
cd packages/ruinous-0p-cli
go test ./...
```

### Building

```bash
cd packages/ruinous-0p-cli
go build -o 0p .
```

## Architecture

### Packages

- `internal/db`: SQLite database for Op persistence
- `internal/worktree`: Git worktree creation and management
- `internal/xdg`: XDG directory setup and cleanup
- `internal/session`: tmuxp session generation

### Commands

- `cmd/new.go`: Create new Ops
- `cmd/list.go`: List Ops
- `cmd/status.go`: Show Op details
- `cmd/attach.go`: Attach to tmux sessions
- `cmd/suspend.go`: Suspend Ops
- `cmd/resume.go`: Resume Ops
- `cmd/complete.go`: Complete and cleanup Ops

## License

MIT
