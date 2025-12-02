#!/usr/bin/env bash
# Refresh SSH_AUTH_SOCK in tmux environment and optionally in a specific pane

set -euo pipefail

show_help() {
  cat << 'EOF'
ssh-agent-refresh - Refresh SSH_AUTH_SOCK in tmux

USAGE:
    ssh-agent-refresh [OPTIONS]

OPTIONS:
    -h, --help          Show this help message and exit
    -q, --quiet         Suppress output messages
    -p, --pane PANE     Send refresh command to specified pane (e.g., "0", "1", "%5")

DESCRIPTION:
    Updates the SSH_AUTH_SOCK environment variable in tmux's global environment.
    This must be run from a pane that has the correct SSH_AUTH_SOCK (typically
    a newly opened pane after reconnecting).

    By default, only updates tmux's environment. New panes will automatically
    inherit the updated value.

    Use --pane to send a refresh command to a specific existing pane. The pane
    can be specified as:
    - A number (e.g., "0", "1") for panes in the current window
    - A pane ID (e.g., "%5") for any pane
    - A full target (e.g., "mysession:1.0")

WORKFLOW:
    1. Open a new tmux pane (it will have the correct SSH_AUTH_SOCK)
    2. Run: ssh-agent-refresh
    3. Optionally refresh other panes: ssh-agent-refresh --pane 0

EXAMPLES:
    # Update tmux environment (run from a new pane)
    ssh-agent-refresh

    # Also refresh pane 0 in current window
    ssh-agent-refresh --pane 0

    # Refresh a specific pane by ID
    ssh-agent-refresh --pane %5

    # Silent mode
    ssh-agent-refresh --quiet --pane 1
EOF
}

# Defaults
QUIET=false
TARGET_PANE=""

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
    -p|--pane)
      TARGET_PANE="$2"
      shift 2
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

log "Current SSH_AUTH_SOCK: $SSH_AUTH_SOCK"

# Update tmux's global environment
tmux set-environment SSH_AUTH_SOCK "$SSH_AUTH_SOCK"
log "Updated tmux environment"

# If a target pane was specified, send refresh command to it
if [ -n "$TARGET_PANE" ]; then
  # The command to send - works for both bash/zsh and fish
  # shellcheck disable=SC2016 # Single quotes are intentional
  refresh_cmd='if test -n "$FISH_VERSION"; set -gx SSH_AUTH_SOCK (tmux show-environment SSH_AUTH_SOCK 2>/dev/null | cut -d= -f2-); else eval "$(tmux show-environment SSH_AUTH_SOCK 2>/dev/null)" 2>/dev/null; fi'

  if tmux send-keys -t "$TARGET_PANE" "$refresh_cmd" Enter 2>/dev/null; then
    log "Sent refresh command to pane: $TARGET_PANE"
  else
    echo "Error: Could not send to pane '$TARGET_PANE'" >&2
    exit 1
  fi
fi

log "Done!"
