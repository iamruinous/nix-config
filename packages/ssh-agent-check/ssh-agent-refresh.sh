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

    If no --pane is specified, an interactive menu lets you select which panes
    to refresh. Use --pane to skip the menu and refresh a specific pane directly.

    The pane can be specified as:
    - A 1-indexed number (e.g., "1", "2") - converted to pane ID automatically
    - A pane ID (e.g., "%5") for any pane
    - A full target (e.g., "mysession:1.0")

WORKFLOW:
    1. Open a new tmux pane (it will have the correct SSH_AUTH_SOCK)
    2. Run: ssh-agent-refresh
    3. Select panes to refresh from the interactive menu

EXAMPLES:
    # Update tmux environment (run from a new pane)
    ssh-agent-refresh

    # Also refresh pane 1 (the first pane)
    ssh-agent-refresh --pane 1

    # Refresh a specific pane by ID
    ssh-agent-refresh --pane %5

    # Silent mode
    ssh-agent-refresh --quiet --pane 2
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

# The command to send - works for both bash/zsh and fish
# shellcheck disable=SC2016 # Single quotes are intentional
refresh_cmd='if test -n "$FISH_VERSION"; set -gx SSH_AUTH_SOCK (tmux show-environment SSH_AUTH_SOCK 2>/dev/null | cut -d= -f2-); else eval "$(tmux show-environment SSH_AUTH_SOCK 2>/dev/null)" 2>/dev/null; fi'

# Function to send refresh command to a pane
send_refresh() {
  local pane="$1"
  if tmux send-keys -t "$pane" "$refresh_cmd" Enter 2>/dev/null; then
    log "Sent refresh command to pane: $pane"
    return 0
  else
    echo "Error: Could not send to pane '$pane'" >&2
    return 1
  fi
}

# If a target pane was specified, send refresh command to it
if [ -n "$TARGET_PANE" ]; then
  # If it's a plain integer, treat it as 1-indexed and convert to %id format
  # e.g., "1" becomes "%0", "2" becomes "%1", etc.
  if [[ "$TARGET_PANE" =~ ^[0-9]+$ ]]; then
    pane_id=$((TARGET_PANE - 1))
    TARGET_PANE="%${pane_id}"
    log "Converted to pane ID: $TARGET_PANE"
  fi

  send_refresh "$TARGET_PANE"
else
  # No pane specified - show interactive selection with gum
  # Get current pane to exclude it from the list
  current_pane="${TMUX_PANE:-}"

  # Build list of panes with their info
  # Format: %id | session:window.pane | current_command
  pane_list=""
  while IFS= read -r line; do
    pane_id=$(echo "$line" | cut -d'|' -f1)
    # Skip current pane
    if [ "$pane_id" != "$current_pane" ]; then
      if [ -n "$pane_list" ]; then
        pane_list="$pane_list"$'\n'"$line"
      else
        pane_list="$line"
      fi
    fi
  done < <(tmux list-panes -a -F '#{pane_id}|#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}')

  if [ -z "$pane_list" ]; then
    log "No other panes to refresh"
    log "Done!"
    exit 0
  fi

  # Use gum to select panes
  log "Select panes to refresh (space to select, enter to confirm):"
  selected=$(echo "$pane_list" | gum choose --no-limit --header "Select panes to refresh:" || true)

  if [ -z "$selected" ]; then
    log "No panes selected"
    log "Done!"
    exit 0
  fi

  # Send refresh to each selected pane
  while IFS= read -r line; do
    pane_id=$(echo "$line" | cut -d'|' -f1)
    send_refresh "$pane_id"
  done <<< "$selected"
fi

log "Done!"
