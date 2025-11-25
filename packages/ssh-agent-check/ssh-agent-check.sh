#!/usr/bin/env bash
# Check if SSH agent is available and responding

set -euo pipefail

show_help() {
  cat << 'EOF'
ssh-agent-check - Check if SSH agent is available and responding

USAGE:
    ssh-agent-check [OPTIONS]

OPTIONS:
    -h, --help    Show this help message and exit

DESCRIPTION:
    Checks whether the SSH agent is available and responding. This is useful
    for scripts that need to verify SSH agent availability before attempting
    operations that require SSH keys (like GPG-signed git commits).

    For local sessions (where SSH_TTY is not set), the check always succeeds.
    For SSH sessions, it verifies that SSH_AUTH_SOCK is set and the agent
    is reachable.

EXIT CODES:
    0    Agent is working (has keys or is reachable with no keys)
    1    Agent is not responding (SSH_AUTH_SOCK invalid or agent dead)

CACHING:
    Results are cached based on the SSH_AUTH_SOCK value. The agent is only
    re-checked if SSH_AUTH_SOCK has changed since the last check.

ENVIRONMENT VARIABLES:
    SSH_TTY         If not set, assumes local session (always returns 0)
    SSH_AUTH_SOCK   Path to the SSH agent socket

EXAMPLES:
    # Check if agent is available before committing
    if ssh-agent-check; then
        git commit -m "message"
    else
        echo "SSH agent not available for signing"
    fi

    # Use in conditional command execution
    ssh-agent-check && git commit -S -m "signed commit"
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/ssh-agent-check-cache-$$"

# Only check SSH agent in SSH sessions
# For local sessions (SSH_TTY not set), return success
if [ -z "${SSH_TTY:-}" ]; then
  exit 0
fi

# Verify SSH_TTY is a valid tty/pty
# This prevents false positives on misconfigured sessions
if ! [ -c "${SSH_TTY:-}" ]; then
  exit 1
fi

# If SSH_AUTH_SOCK is not set, agent is not available
if [ -z "${SSH_AUTH_SOCK:-}" ]; then
  exit 1
fi

# Check if we have a cached result for this SSH_AUTH_SOCK
if [ -f "$CACHE_FILE" ]; then
  read -r cached_sock cached_result < "$CACHE_FILE" 2>/dev/null || true

  # If SSH_AUTH_SOCK hasn't changed, return cached result
  if [ "$cached_sock" = "$SSH_AUTH_SOCK" ]; then
    exit "$cached_result"
  fi
fi

# Try to contact the agent with ssh-add -L
# Exit codes from ssh-add:
#   0 - Agent has identities
#   1 - Agent reachable but no identities
#   2 - Cannot contact agent
ssh-add -L >/dev/null 2>&1
exit_code=$?

# Agent is working if exit code is 0 or 1
# Agent is broken if exit code is 2
if [ "$exit_code" -eq 2 ]; then
  result=1
else
  result=0
fi

# Cache the result
echo "$SSH_AUTH_SOCK $result" > "$CACHE_FILE"

exit "$result"
