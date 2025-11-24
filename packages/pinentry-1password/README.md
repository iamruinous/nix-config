# pinentry-1password

A pinentry-compatible program that uses 1Password CLI to retrieve passphrases. This allows programs like `rage`, `gpg-agent`, and other tools that support the pinentry protocol to retrieve secrets from 1Password.

## Overview

Based on [this gist](https://gist.github.com/mrgrain/9c3519952d9af811bd7bf50bfcfaa16f), this package provides a `pinentry-1password` command that implements the pinentry protocol and retrieves secrets from 1Password using the `op` CLI tool.

## Prerequisites

- 1Password CLI (`op`) must be installed and authenticated
- You must be signed in to 1Password (`op signin`)

## Usage

### Manual Usage

Set the `OP_PIN_ITEM` environment variable to your 1Password secret reference and `PINENTRY_PROGRAM` to point to this program:

```bash
export OP_PIN_ITEM="op://vault/item/field"
export PINENTRY_PROGRAM="pinentry-1password"
```

Then use with any pinentry-compatible program:

```bash
# With rage
rage -d -i identity.age file.age

# With age (via agenix-helper)
agenix-helper unlock
```

### 1Password Secret Reference Format

The `OP_PIN_ITEM` should be in the format: `op://vault/item/field`

Examples:
- `op://Private/age-identity/password`
- `op://Work/gpg-key/passphrase`

### Integration with agenix-helper

The `agenix-helper unlock` command automatically detects and uses `pinentry-1password` when:
1. The `op` command is available on the system
2. The `pinentry-1password` package is installed
3. The `OP_PIN_ITEM` environment variable is set

This allows you to unlock your age identity using a passphrase stored in 1Password:

```bash
export OP_PIN_ITEM="op://Private/age-identity/passphrase"
agenix-helper unlock
```

## How It Works

The program implements the pinentry protocol:
1. Reads commands from stdin
2. When it receives `GETPIN`, it executes `op read $OP_PIN_ITEM`
3. Returns the secret in the pinentry protocol format
4. Handles errors gracefully with appropriate error codes

## Error Handling

- If `OP_PIN_ITEM` is not set, returns error code 83886179
- If `op` command is not found, returns error code 83886179
- If reading from 1Password fails, returns error code 83886179

## Security Considerations

- The passphrase is retrieved from 1Password each time it's needed
- No passphrases are stored on disk by this program
- Requires an active 1Password CLI session
- Uses standard pinentry protocol for secure communication

## Installation

This package is automatically available via the NixOS overlay when building from this flake:

```nix
# In your configuration
environment.systemPackages = [
  pkgs.pinentry-1password
];
```

Or add to your home-manager configuration:

```nix
home.packages = [
  pkgs.pinentry-1password
];
```
