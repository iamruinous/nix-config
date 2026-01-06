#!/usr/bin/env bash
#
# apprise-notify - Send notifications via Apprise API
#
# Usage:
#   apprise-notify <message> [title] [type]
#
# Environment Variables:
#   APPRISE_API_URL  Apprise API server URL (required, e.g., http://localhost:8000)
#   APPRISE_URLS     Notification service URLs (optional, uses server default if not set)
#   APPRISE_TAG      Filter notifications by tag (optional)
#
# Arguments:
#   message   Notification body text (required)
#   title     Notification title (optional, default: "OpenCode")
#   type      Notification type: info, success, warning, failure (optional, default: info)
#
# Examples:
#   apprise-notify "Task completed"
#   apprise-notify "Build failed" "CI/CD" "failure"
#   APPRISE_URLS="slack://token" apprise-notify "Deployed!" "Deploy" "success"
#

set -euo pipefail

# Show help
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    sed -n '/^# Usage:/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \?//'
    exit 0
fi

# Validate required environment
if [[ -z "${APPRISE_API_URL:-}" ]]; then
    echo "Error: APPRISE_API_URL environment variable is required" >&2
    echo "Example: export APPRISE_API_URL=http://localhost:8000" >&2
    exit 1
fi

# Parse arguments
MESSAGE="${1:-}"
TITLE="${2:-OpenCode}"
TYPE="${3:-info}"

if [[ -z "$MESSAGE" ]]; then
    echo "Error: Message is required" >&2
    echo "Usage: apprise-notify <message> [title] [type]" >&2
    exit 1
fi

# Validate type
case "$TYPE" in
    info|success|warning|failure) ;;
    *)
        echo "Error: Invalid type '$TYPE'. Must be: info, success, warning, failure" >&2
        exit 1
        ;;
esac

# Build JSON payload
PAYLOAD=$(cat <<EOF
{
  "body": $(echo -n "$MESSAGE" | @jq@ -Rs .),
  "title": $(echo -n "$TITLE" | @jq@ -Rs .),
  "type": "$TYPE",
  "format": "text"
}
EOF
)

# Add optional urls if set
if [[ -n "${APPRISE_URLS:-}" ]]; then
    PAYLOAD=$(echo "$PAYLOAD" | @jq@ --arg urls "$APPRISE_URLS" '. + {urls: $urls}')
fi

# Add optional tag if set
if [[ -n "${APPRISE_TAG:-}" ]]; then
    PAYLOAD=$(echo "$PAYLOAD" | @jq@ --arg tag "$APPRISE_TAG" '. + {tag: $tag}')
fi

# Close JSON object
PAYLOAD=$(echo "$PAYLOAD" | @jq@ -c .)

# Send notification
ENDPOINT="${APPRISE_API_URL%/}/notify/"

RESPONSE=$(@curl@ -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$ENDPOINT" 2>&1) || {
    echo "Error: Failed to send notification to $ENDPOINT" >&2
    exit 1
}

# Extract HTTP status code (last line)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

case "$HTTP_CODE" in
    200)
        echo "Notification sent successfully"
        ;;
    400)
        echo "Error: Bad request - check your payload" >&2
        echo "$BODY" >&2
        exit 1
        ;;
    424)
        echo "Warning: Some notifications failed to send" >&2
        echo "$BODY" >&2
        exit 0  # Partial success
        ;;
    *)
        echo "Error: Unexpected response (HTTP $HTTP_CODE)" >&2
        echo "$BODY" >&2
        exit 1
        ;;
esac
