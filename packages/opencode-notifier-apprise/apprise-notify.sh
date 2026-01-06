#!/usr/bin/env bash
#
# apprise-notify - Send notifications via Apprise API
#
# Usage:
#   apprise-notify <message> [title] [type]
#
# Environment Variables:
#   OPENCODE_NOTIFIER_APPRISE_URL         Full endpoint URL, or base URL with CONFIG_KEY
#   OPENCODE_NOTIFIER_APPRISE_CONFIG_KEY  Config key - builds {URL}/notify/{KEY}/
#   OPENCODE_NOTIFIER_APPRISE_URLS        Notification service URLs (optional)
#   OPENCODE_NOTIFIER_APPRISE_TAG         Filter by tag (optional)
#
# Arguments:
#   message   Notification body text (required)
#   title     Notification title (optional, default: "OpenCode")
#   type      Notification type: info, success, warning, failure (optional, default: info)
#
# Examples:
#   apprise-notify "Task completed"
#   apprise-notify "Build failed" "CI/CD" "failure"
#   OPENCODE_NOTIFIER_APPRISE_URLS="slack://token" apprise-notify "Deployed!"
#

set -euo pipefail

# Show help
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    sed -n '/^# Usage:/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \?//'
    exit 0
fi

# Validate required environment
if [[ -z "${OPENCODE_NOTIFIER_APPRISE_URL:-}" ]]; then
    echo "Error: OPENCODE_NOTIFIER_APPRISE_URL environment variable is required" >&2
    echo "Example: export OPENCODE_NOTIFIER_APPRISE_URL=https://apprise.example.com/notify/myconfig/" >&2
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
if [[ -n "${OPENCODE_NOTIFIER_APPRISE_URLS:-}" ]]; then
    PAYLOAD=$(echo "$PAYLOAD" | @jq@ --arg urls "$OPENCODE_NOTIFIER_APPRISE_URLS" '. + {urls: $urls}')
fi

if [[ -n "${OPENCODE_NOTIFIER_APPRISE_TAG:-}" ]]; then
    PAYLOAD=$(echo "$PAYLOAD" | @jq@ --arg tag "$OPENCODE_NOTIFIER_APPRISE_TAG" '. + {tag: $tag}')
fi

# Close JSON object
PAYLOAD=$(echo "$PAYLOAD" | @jq@ -c .)

if [[ -n "${OPENCODE_NOTIFIER_APPRISE_CONFIG_KEY:-}" ]]; then
    ENDPOINT="${OPENCODE_NOTIFIER_APPRISE_URL%/}/notify/${OPENCODE_NOTIFIER_APPRISE_CONFIG_KEY}/"
else
    ENDPOINT="${OPENCODE_NOTIFIER_APPRISE_URL%/}/"
fi

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
