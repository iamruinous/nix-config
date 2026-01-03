#!/usr/bin/env bash
# ruinous-xdg-receiver
set -euo pipefail

STATE_DIR="$HOME/.local/state/ruinous-xdg-receiver"
CONN_FILE="$STATE_DIR/connection-string"
GUM="@gum@/bin/gum"
OPENSSL="@openssl@/bin/openssl"
PYTHON="@python@/bin/python3"

mkdir -p "$STATE_DIR"

setup_receiver() {
    $GUM style --foreground 212 --border-foreground 212 --border rounded --padding "1 2" "XDG Remote Receiver Setup"

    DEFAULT_FQDN=$(hostname -f 2>/dev/null || hostname)
    FQDN=$($GUM input --header "Enter your FQDN or IP address" --value "$DEFAULT_FQDN")
    
    DEFAULT_PORT=$((RANDOM % 10000 + 40000))
    PORT=$($GUM input --header "Enter listener port" --value "$DEFAULT_PORT")
    
    KEY=$($OPENSSL rand -hex 16)
    
    # Create JSON connection info
    # Format: host:port:key (simple colon separated or JSON)
    # Let's use JSON base64 encoded as it's cleaner for extensions
    CONN_STR=$(echo -n "{\"host\":\"$FQDN\",\"port\":$PORT,\"key\":\"$KEY\"}" | base64 -w0)
    
    echo "$CONN_STR" > "$CONN_FILE"
    
    $GUM style --foreground 118 "Configuration saved to $CONN_FILE"
}

if [[ "${1:-}" == "--reset" ]]; then
    rm -f "$CONN_FILE"
    setup_receiver
fi

if [[ ! -f "$CONN_FILE" ]]; then
    setup_receiver
else
    # Check if user wants to reset
    if [[ "${1:-}" != "--start" ]]; then
        if $GUM confirm "Existing configuration found. Start receiver?"; then
            true
        else
            if $GUM confirm "Reset configuration?"; then
                rm -f "$CONN_FILE"
                setup_receiver
            else
                exit 0
            fi
        fi
    fi
fi

CONN_STR=$(cat "$CONN_FILE")
# Decode for local use
DECODED=$(echo "$CONN_STR" | base64 -d)
HOST=$(echo "$DECODED" | @python@/bin/python3 -c "import sys, json; print(json.load(sys.stdin)['host'])")
PORT=$(echo "$DECODED" | @python@/bin/python3 -c "import sys, json; print(json.load(sys.stdin)['port'])")
KEY=$(echo "$DECODED" | @python@/bin/python3 -c "import sys, json; print(json.load(sys.stdin)['key'])")

$GUM style --foreground 212 --border-foreground 212 --border double \
    "XDG Remote Receiver" \
    "Listening on $HOST:$PORT" \
    "" \
    "Connection String:" \
    "$CONN_STR"

# Start receiver server
$PYTHON -c "
import http.server
import socketserver
import json
import subprocess
import sys

PORT = $PORT
KEY = '$KEY'
GUM = '$GUM'

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        try:
            data = json.loads(post_data)
            if data.get('key') == KEY:
                url = data.get('url')
                # Use gum to display the received URL nicely
                subprocess.run([GUM, 'style', '--foreground', '118', '--border', 'rounded', '--padding', '1 2', f'Received URL: {url}'])
                # Also print to stdout for logging/piping
                print(f'{url}')
                sys.stdout.flush()
                
                # Optional: try to open it locally if xdg-open exists
                # subprocess.run(['xdg-open', url])

                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'OK')
            else:
                self.send_response(403)
                self.end_headers()
                self.wfile.write(b'Forbidden')
        except Exception as e:
            print(f'Error processing request: {e}')
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b'Bad Request')

    def log_message(self, format, *args):
        return

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(('', PORT), Handler) as httpd:
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\nStopping receiver...')
        sys.exit(0)
"
