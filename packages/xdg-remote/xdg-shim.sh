#!/usr/bin/env bash
# ruinous-xdg-shim
set -euo pipefail

STATE_DIR="$HOME/.local/state/ruinous-xdg-shim"
CONN_FILE="$STATE_DIR/connection-string"
GUM="@gum@/bin/gum"

mkdir -p "$STATE_DIR"

setup_shim() {
    $GUM style --foreground 212 --border-foreground 212 --border rounded --padding "1 2" "XDG Remote Shim Setup"
    
    CONN_STR=$($GUM input --header "Paste connection string from receiver" --placeholder "eyJhostIjo...")
    
    if [[ -n "$CONN_STR" ]]; then
        echo "$CONN_STR" > "$CONN_FILE"
        $GUM style --foreground 118 "Configuration saved to $CONN_FILE"
    else
        echo "No connection string provided."
        exit 1
    fi
}

if [[ "${1:-}" == "--reset" ]] || [[ ! -f "$CONN_FILE" ]]; then
    setup_shim
else
    $GUM style --foreground 118 "Shim is configured. Use 'xdg-open <url>' to send URLs to your receiver."
    if $GUM confirm "Update connection string?"; then
        setup_shim
    fi
fi
