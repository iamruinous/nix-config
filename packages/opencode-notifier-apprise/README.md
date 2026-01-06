# opencode-notifier-apprise

OpenCode plugin that sends notifications via [Apprise API](https://github.com/caronc/apprise-api) when user attention is needed.

## Overview

This package provides two components:

1. **OpenCode Plugin** - Automatically sends notifications when:
   - Session becomes idle (waiting for user input)
   - Permission is requested
   - Session errors occur

2. **CLI Tool (`apprise-notify`)** - Standalone command for sending notifications directly

## Prerequisites

You need an Apprise API server running. The easiest way is via Docker:

```bash
docker run -d --name apprise \
  -p 8000:8000 \
  -e APPRISE_STATELESS_URLS="slack://token1/token2/token3" \
  caronc/apprise:latest
```

## Installation

### As a Nix Package

Add to your NixOS/home-manager configuration:

```nix
environment.systemPackages = with pkgs; [
  opencode-notifier-apprise
];
```

### OpenCode Plugin Setup

The plugin needs to be installed in your OpenCode configuration:

**Option 1: Local Plugin (Recommended)**

Copy the plugin source to your local OpenCode plugin directory:

```bash
# Create plugin directory if it doesn't exist
mkdir -p ~/.config/opencode/plugin

# Copy the plugin
cp -r /path/to/nix-store/share/opencode-notifier-apprise/* ~/.config/opencode/plugin/apprise-notifier/

# Install dependencies
cd ~/.config/opencode/plugin/apprise-notifier
bun install
bun run build
```

**Option 2: Add to opencode.json**

If published to npm, add to your `~/.config/opencode/opencode.json`:

```json
{
  "plugin": [
    "opencode-notifier-apprise"
  ]
}
```

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `APPRISE_API_URL` | Yes | - | Apprise API server URL (e.g., `http://localhost:8000`) |
| `APPRISE_URLS` | No | - | Notification service URLs (overrides server default) |
| `APPRISE_TAG` | No | - | Filter notifications by tag |
| `OPENCODE_NOTIFY_IDLE_DELAY` | No | `5000` | Delay in ms before sending idle notification |
| `OPENCODE_NOTIFY_ON_PERMISSION` | No | `true` | Send notification on permission requests |
| `OPENCODE_NOTIFY_ON_ERROR` | No | `true` | Send notification on session errors |

### Example Configuration

Add to your shell profile (`.bashrc`, `.zshrc`, `config.fish`):

```bash
export APPRISE_API_URL="http://localhost:8000"
export APPRISE_URLS="slack://token1/token2/token3"
export OPENCODE_NOTIFY_IDLE_DELAY="10000"  # 10 seconds
```

Or in fish:

```fish
set -gx APPRISE_API_URL "http://localhost:8000"
set -gx APPRISE_URLS "slack://token1/token2/token3"
```

## CLI Usage

The `apprise-notify` command can be used independently:

```bash
# Basic usage
apprise-notify "Build completed successfully"

# With title and type
apprise-notify "Deployment failed" "CI/CD" "failure"

# With custom notification URLs
APPRISE_URLS="discord://webhook" apprise-notify "New commit" "Git" "info"
```

### Arguments

```
apprise-notify <message> [title] [type]

Arguments:
  message   Notification body text (required)
  title     Notification title (optional, default: "OpenCode")
  type      Notification type: info, success, warning, failure (optional, default: info)
```

### Notification Types

| Type | Use Case |
|------|----------|
| `info` | General information (default) |
| `success` | Task completed successfully |
| `warning` | Attention needed, permission requests |
| `failure` | Errors, failures |

## Supported Notification Services

Apprise supports 100+ notification services. Common examples:

| Service | URL Format |
|---------|------------|
| Slack | `slack://TokenA/TokenB/TokenC` |
| Discord | `discord://webhook_id/webhook_token` |
| Telegram | `tgram://bot_token/chat_id` |
| Email | `mailto://user:pass@gmail.com` |
| Pushover | `pover://user@token` |
| ntfy | `ntfy://topic` |
| Gotify | `gotify://hostname/token` |

See [Apprise Wiki](https://github.com/caronc/apprise/wiki) for the full list.

## Plugin Events

The plugin listens for these OpenCode events:

### `session.idle`

Triggered when OpenCode finishes processing and is waiting for user input. The notification includes a summary of the last assistant message.

**Notification:**
- Title: "OpenCode - Waiting for Input"
- Type: `info`
- Body: Summary of last message or detected question

### `permission.asked`

Triggered when OpenCode needs permission to perform an action (file access, command execution, etc.).

**Notification:**
- Title: "OpenCode - Permission Required"
- Type: `warning`
- Body: Permission type and affected patterns

### `session.error`

Triggered when a session error occurs.

**Notification:**
- Title: "OpenCode - Error"
- Type: `failure`
- Body: Error message

## Troubleshooting

### Notifications not sending

1. Verify `APPRISE_API_URL` is set and the server is reachable:
   ```bash
   curl -X POST -d '{"body":"test"}' -H "Content-Type: application/json" $APPRISE_API_URL/notify/
   ```

2. Check OpenCode logs for plugin errors

3. Verify the plugin is loaded:
   ```bash
   # Check if plugin directory exists
   ls ~/.config/opencode/plugin/
   ```

### Too many notifications

Increase the idle delay:
```bash
export OPENCODE_NOTIFY_IDLE_DELAY="30000"  # 30 seconds
```

Or disable specific notification types:
```bash
export OPENCODE_NOTIFY_ON_PERMISSION="false"
```

## Development

### Building from Source

```bash
cd packages/opencode-notifier-apprise

# Install dependencies
bun install

# Build
bun run build

# Type check
bun run typecheck
```

### Testing the CLI

```bash
# Build the Nix package
nix build .#opencode-notifier-apprise

# Test the CLI
export APPRISE_API_URL="http://localhost:8000"
./result/bin/apprise-notify "Test message" "Test" "info"
```

## Version

0.1.0

## License

MIT
