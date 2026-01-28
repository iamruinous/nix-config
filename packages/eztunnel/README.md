# eztunnel

Simple SSH local tunnel utility for accessing remote ports via localhost.

## Overview

`eztunnel` creates an SSH local tunnel to forward a remote port to your local machine. This is useful for accessing services running on remote hosts as if they were running locally.

## Features

- Simple command-line interface with sensible defaults
- **Interactive mode** when no arguments are provided (powered by `gum`)
- Configurable local and remote ports
- Connection keep-alive with automatic reconnection
- Auto-accepts new host keys for convenience
- Help text via `--help` or `-h`

## Usage

### Interactive Mode

Simply run `eztunnel` without arguments to launch the interactive wizard:

```bash
eztunnel
```

### Command Line Mode

```bash
eztunnel <remote-host> [remote-port] [local-port]
```

## OAuth Helper (ezoauth)

`ezoauth` is a helper script that automatically sets up a tunnel based on an OAuth URL. It parses the `redirect_uri` parameter to extract the required port.

```bash
ezoauth <remote-host> <oauth-url>
```

**Example:**

```bash
ezoauth zenith "https://github.com/login/oauth/authorize?client_id=...&redirect_uri=http://localhost:3000/callback"
# Automatically runs: eztunnel zenith 3000
```

### Arguments

- `remote-host` (required): Remote server hostname
- `remote-port` (optional): Port on remote server (default: 8765)
- `local-port` (optional): Local port to bind (default: same as remote-port)

### Examples

```bash
# Access zenith:8765 via localhost:8765
eztunnel zenith

# Access zenith:9000 via localhost:9000
eztunnel zenith 9000

# Access zenith:9000 via localhost:3000 (port forwarding)
eztunnel zenith 9000 3000
```

## Common Use Cases

### OAuth Authentication for AI Agents

When AI agents need OAuth authentication on headless servers without browsers, tunnel the callback port to your local machine:

```bash
# On your local machine with a browser
eztunnel remote-server 8765
# Now OAuth callbacks to remote-server:8765 are available at localhost:8765
```

### Accessing n8n webhooks during development
```bash
eztunnel zenith 5678
# Now access http://localhost:5678 in your browser
```

### Accessing a remote database
```bash
eztunnel database-host 5432
# Connect your database client to localhost:5432
```

### Accessing any remote web service
```bash
eztunnel webserver 8080 8000
# Access the remote service at http://localhost:8000
```

## Technical Details

The tunnel is created with the following SSH options:

- `StrictHostKeyChecking=accept-new`: Automatically accepts new host keys
- `ServerAliveInterval=30`: Sends keep-alive packets every 30 seconds
- `ServerAliveCountMax=3`: Disconnects after 3 failed keep-alive attempts
- `SetEnv=BYPASS_LOGIN_HUB=true`: Bypasses login hub interactive prompts
- `RequestTTY=no`: Prevents TTY allocation for non-interactive operation
- `LogLevel=ERROR`: Suppresses non-error SSH messages
- `-N`: No remote command execution (tunnel only)
- `-L`: Local port forwarding

## Installation

This package is automatically available on all hosts in this flake via the custom overlay.

Add to your configuration:

```nix
environment.systemPackages = with pkgs; [
  eztunnel
];
```

Or use directly in your home-manager configuration:

```nix
home.packages = with pkgs; [
  eztunnel
];
```

## Dependencies

- openssh: Required for the `ssh` command
- gum: Required for interactive mode
- python3: Required for `ezoauth` URL parsing

## Stopping the Tunnel

Press `Ctrl+C` to stop the tunnel and close the connection.

## Version

1.0.0

## License

MIT
