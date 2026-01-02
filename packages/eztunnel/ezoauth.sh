#!/usr/bin/env bash
#
# ezoauth - Helper for Oauth callbacks via eztunnel
#
# Parses a redirect_uri from an OAuth URL and sets up an eztunnel for it.
#
# Usage:
#   ezoauth <remote-host> <oauth-url>
#

set -euo pipefail

if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    sed -n '/^# Usage:/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \?//'
    exit 0
fi

REMOTE_HOST="${1:-}"
OAUTH_URL="${2:-}"

GUM="@gum@/bin/gum"

if [[ -z "$REMOTE_HOST" ]]; then
    if [ -x "$GUM" ]; then
        REMOTE_HOST=$($GUM input --header "Remote Hostname" --placeholder "e.g. zenith")
    else
        echo "Error: Remote hostname required."
        exit 1
    fi
fi

if [[ -z "$OAUTH_URL" ]]; then
    if [ -x "$GUM" ]; then
        OAUTH_URL=$($GUM input --header "OAuth URL" --placeholder "Paste the full OAuth URL here")
    else
        echo "Error: OAuth URL required."
        exit 1
    fi
fi

if [[ -z "$REMOTE_HOST" ]] || [[ -z "$OAUTH_URL" ]]; then
    echo "Error: Missing arguments."
    echo "Usage: ezoauth <remote-host> <oauth-url>"
    exit 1
fi

# Extract port using python for reliable URL parsing and decoding
PORT=$(@python@/bin/python3 -c "
import sys
import urllib.parse as ul

url = sys.argv[1]
parsed = ul.urlparse(url)
qs = ul.parse_qs(parsed.query)

redirect_uri = qs.get('redirect_uri', [None])[0]

if not redirect_uri:
    # Try looking in 'redirect_url' as a fallback
    redirect_uri = qs.get('redirect_url', [None])[0]

if not redirect_uri:
    print('Error: Could not find redirect_uri or redirect_url query parameter', file=sys.stderr)
    sys.exit(1)

# Parse the redirect uri to get the port
callback_parsed = ul.urlparse(redirect_uri)
port = callback_parsed.port

if not port:
    # If no port is specified, assume 80 for http and 443 for https, though usually it's a specific port for local dev
    if callback_parsed.scheme == 'http':
        port = 80
    elif callback_parsed.scheme == 'https':
        port = 443
    else:
        print(f'Error: Could not determine port from redirect_uri: {redirect_uri}', file=sys.stderr)
        sys.exit(1)

print(port)
" "$OAUTH_URL")

echo "Found callback port: $PORT"
echo "Starting eztunnel..."
echo ""

# Execute eztunnel with the extracted port
# We assume eztunnel is in the path or strictly relative
# Since this script will be in the same bin dir, we can try invoking it directly if valid
# But relying on PATH is safer if installed together

exec eztunnel "$REMOTE_HOST" "$PORT"
