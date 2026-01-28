#!/usr/bin/env bash
#
# eztunnel - Simple SSH local tunnel
#
# Creates an SSH local tunnel to access a remote port from localhost.
#
# Usage:
#   eztunnel <remote-host> [remote-port] [local-port]
#
# Arguments:
#   remote-host   Remote server hostname (required)
#   remote-port   Port on remote server (default: 8765)
#   local-port    Local port to bind (default: same as remote-port)
#
# Examples:
#   eztunnel zenith              # Access zenith:8765 via localhost:8765
#   eztunnel zenith 9000         # Access zenith:9000 via localhost:9000
#   eztunnel zenith 9000 3000    # Access zenith:9000 via localhost:3000
#

set -euo pipefail

if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    sed -n '/^# Usage:/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \?//'
    exit 0
fi

GUM="@gum@/bin/gum"

if [[ $# -eq 0 ]]; then
    # Interactive mode
    if [ ! -x "$GUM" ]; then
        echo "Error: gum is not available. Please provide arguments."
        exit 1
    fi

    $GUM style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        "eztunnel" "Simple SSH Local Tunnel"

    REMOTE_HOST=$($GUM input --header "Remote Hostname" --placeholder "e.g. zenith")
    if [ -z "$REMOTE_HOST" ]; then
        echo "Hostname is required."
        exit 1
    fi

    REMOTE_PORT=$($GUM input --header "Remote Port" --value "8765")
    LOCAL_PORT=$($GUM input --header "Local Port" --value "$REMOTE_PORT")
else
    REMOTE_HOST="$1"
    REMOTE_PORT="${2:-8765}"
    LOCAL_PORT="${3:-$REMOTE_PORT}"
fi

# Display summary header
if [ -x "$GUM" ]; then
    $GUM style \
        --foreground 212 --border-foreground 213 --border rounded \
        --padding "2 4" \
        --margin "1 0" \
        "eztunnel" \
        "localhost:${LOCAL_PORT} -> ${REMOTE_HOST}:${REMOTE_PORT}"
else
    echo "Creating tunnel: localhost:${LOCAL_PORT} -> ${REMOTE_HOST}:${REMOTE_PORT}"
    echo "Press Ctrl+C to stop"
    echo ""
fi

SSH_CMD="@ssh@/bin/ssh -o StrictHostKeyChecking=accept-new \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o SetEnv=BYPASS_LOGIN_HUB=true \
    -o RequestTTY=no \
    -o LogLevel=ERROR \
    -L ${LOCAL_PORT}:localhost:${REMOTE_PORT} \
    -N \
    ${REMOTE_HOST}"

if [ -x "$GUM" ]; then
    $GUM spin --spinner dot \
        --title "Tunnel Active (Ctrl+C to stop)" \
        --show-output \
        -- $SSH_CMD
else
    $SSH_CMD
fi
