#!/usr/bin/env bash
# Refresh SSH_AUTH_SOCK across all tmux panes

set -euo pipefail

show_help() {
  cat << 'EOF'
ssh-agent-refresh - Refresh SSH_AUTH_SOCK across tmux panes

USAGE:
    ssh-agent-refresh [OPTIONS]

OPTIONS:
    -h, --help      Show this help message and exit
    -q, --quiet     Suppress output messages
    -n, --dry-run   Show what would be done without executing
    -c, --current   Only update tmux environment (for current pane via keybinding)

DESCRIPTION:
    Updates the SSH_AUTH_SOCK environment variable in tmux and optionally
    across all tmux panes. This is useful when the SSH agent socket has
    changed (e.g., after reconnecting to a remote session).

    The command works by:
    1. Updating tmux's stored environment with the current SSH_AUTH_SOCK
    2. Optionally sending a command to each tmux pane to refresh its
       SSH_AUTH_SOCK from tmux's environment

    With --current, only step 1 is performed. New panes and shells will
    automatically pick up the new SSH_AUTH_SOCK from tmux's environment.
    Existing panes can refresh by running: eval "$(tmux show-env -s)"

REQUIREMENTS:
    - Must be run inside a tmux session OR have TMUX_PANE set
    - SSH_AUTH_SOCK must be set in the current environment

EXAMPLES:
    # Update tmux environment only (recommended for keybindings)
    ssh-agent-refresh --current

    # Refresh all panes after reconnecting
    ssh-agent-refresh

    # Preview what would be refreshed
    ssh-agent-refresh --dry-run

    # Silent refresh (for scripts)
    ssh-agent-refresh --quiet
EOF
}

# Defaults
QUIET=false
DRY_RUN=false
CURRENT_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -q|--quiet)
      QUIET=true
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -c|--current)
      CURRENT_ONLY=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

log() {
  if [ "$QUIET" = false ]; then
    echo "$@"
  fi
}

# Check if we're in tmux (either via TMUX or TMUX_PANE for run-shell commands)
if [ -z "${TMUX:-}" ] && [ -z "${TMUX_PANE:-}" ]; then
  echo "Error: Not running inside tmux" >&2
  exit 1
fi

# Check if SSH_AUTH_SOCK is set
if [ -z "${SSH_AUTH_SOCK:-}" ]; then
  echo "Error: SSH_AUTH_SOCK is not set" >&2
  exit 1
fi

# Check if the socket exists
if [ ! -S "$SSH_AUTH_SOCK" ]; then
  echo "Error: SSH_AUTH_SOCK ($SSH_AUTH_SOCK) is not a valid socket" >&2
  exit 1
fi

log "Current SSH_AUTH_SOCK: $SSH_AUTH_SOCK"

# Update tmux's environment
if [ "$DRY_RUN" = true ]; then
  log "[dry-run] Would update tmux environment: SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
else
  tmux set-environment SSH_AUTH_SOCK "$SSH_AUTH_SOCK"
  log "Updated tmux environment"
fi

# If --current flag is set, only update tmux environment and exit
if [ "$CURRENT_ONLY" = true ]; then
  if [ "$DRY_RUN" = false ]; then
    log "Done! Tmux environment updated. New shells will use the new SSH_AUTH_SOCK."
    log "Run 'eval \"\$(tmux show-env -s)\"' in existing shells to refresh."
  fi
  exit 0
fi

# Get list of all panes
panes=$(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}')
pane_count=$(echo "$panes" | wc -l)

log "Refreshing $pane_count pane(s)..."

# The command to send to each pane - must work for both bash/zsh and fish
# We use tmux show-env -s which outputs shell-compatible format for POSIX shells
# For fish, we need a different approach
# shellcheck disable=SC2016 # Single quotes are intentional - we want literal string sent to panes
refresh_cmd='if test -n "$FISH_VERSION"; set -gx SSH_AUTH_SOCK (tmux show-environment SSH_AUTH_SOCK 2>/dev/null | cut -d= -f2-); else eval "$(tmux show-environment SSH_AUTH_SOCK 2>/dev/null)" 2>/dev/null; fi'

# Send command to each pane
for pane in $panes; do
  if [ "$DRY_RUN" = true ]; then
    log "[dry-run] Would refresh pane: $pane"
  else
    tmux send-keys -t "$pane" "$refresh_cmd" Enter
    log "Refreshed pane: $pane"
  fi
done

if [ "$DRY_RUN" = true ]; then
  log "[dry-run] No changes made"
else
  log "Done! All panes have been sent the refresh command."
fi
