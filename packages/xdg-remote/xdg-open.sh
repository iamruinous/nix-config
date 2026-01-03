#!/usr/bin/env bash
# xdg-open shim
set -euo pipefail

STATE_DIR="$HOME/.local/state/ruinous-xdg-shim"
CONN_FILE="$STATE_DIR/connection-string"
CURL="@curl@/bin/curl"
PYTHON="@python@/bin/python3"

if [[ ! -f "$CONN_FILE" ]]; then
    echo "Error: xdg-remote-shim not configured. Run 'xdg-remote-shim' first." >&2
    exit 1
fi

URL="${1:-}"
if [[ -z "$URL" ]]; then
    echo "Usage: xdg-open <url>" >&2
    exit 1
fi

CONN_STR=$(cat "$CONN_FILE")
DECODED=$(echo "$CONN_STR" | base64 -d)
HOST=$(echo "$DECODED" | $PYTHON -c "import sys, json; print(json.load(sys.stdin)['host'])")
PORT=$(echo "$DECODED" | $PYTHON -c "import sys, json; print(json.load(sys.stdin)['port'])")
KEY=$(echo "$DECODED" | $PYTHON -c "import sys, json; print(json.load(sys.stdin)['key'])")

# Send the URL to the receiver
PAYLOAD=$(printf '{"url": "%s", "key": "%s"}' "$URL" "$KEY")

$CURL -s -X POST "http://$HOST:$PORT" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" > /dev/null || {
        echo "Failed to send URL to receiver at $HOST:$PORT" >&2
        exit 1
    }
