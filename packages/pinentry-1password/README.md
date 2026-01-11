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

### Environment Variables

| Variable | Description | Precedence |
|----------|-------------|------------|
| `PINENTRY_USER_DATA` | Dynamic per-call secret reference | **Highest** (checked first) |
| `OP_PIN_ITEM` | Static secret reference | Fallback if PINENTRY_USER_DATA not set |

**Note:** `PINENTRY_USER_DATA` is passed by programs like `rage` to pinentry programs, allowing dynamic per-call configuration. This is particularly useful when the calling program (like `agenix-helper`) needs to specify which secret to retrieve at runtime.

### 1Password Secret Reference Format

Both `OP_PIN_ITEM` and `PINENTRY_USER_DATA` should be in the format: `op://vault/item/field`

Examples:
- `op://Private/age-identity/password`
- `op://Work/gpg-key/passphrase`

### Integration with agenix-helper

The `agenix-helper unlock` command automatically detects and uses `pinentry-1password` when:
1. The `op` command is available on the system
2. The `pinentry-1password` package is installed
3. Either `AGENIX_HELPER_OP_HOST_SECRET` or `AGENIX_HELPER_OP_USER_SECRET` is set

This allows you to unlock your age identity using a passphrase stored in 1Password:

```bash
export AGENIX_HELPER_OP_HOST_SECRET="op://Private/age-identity/passphrase"
agenix-helper unlock
```

`agenix-helper` will set `OP_PIN_ITEM` and `PINENTRY_PROGRAM` automatically before calling `rage`.

## How It Works

The program implements the pinentry protocol:
1. Reads commands from stdin
2. When it receives `GETPIN`, it retrieves the secret reference from `PINENTRY_USER_DATA` (if set) or `OP_PIN_ITEM`
3. Executes `op read <secret-reference>` to retrieve the passphrase
4. Returns the secret in the pinentry protocol format
5. Handles errors gracefully with appropriate error codes

## Error Handling

- If neither `PINENTRY_USER_DATA` nor `OP_PIN_ITEM` is set, returns error code 83886179
- If `op` command is not found, returns error code 83886179
- If reading from 1Password fails, returns error code 83886179

## Testing

This package includes Nix-based tests. To run them:

```bash
# Run all tests
nix build .#pinentry-1password.passthru.tests.greeting
nix build .#pinentry-1password.passthru.tests.getinfo-version
nix build .#pinentry-1password.passthru.tests.getpin-op-pin-item
nix build .#pinentry-1password.passthru.tests.getpin-pinentry-user-data
# ... and more

# Or run specific tests
nix build .#pinentry-1password.passthru.tests.getpin-pinentry-user-data
```

Available tests:
- `greeting` - Initial OK greeting
- `getinfo-version` - Version info response
- `getinfo-pid` - PID info response
- `getinfo-flavor` - Flavor info response
- `getpin-op-pin-item` - GETPIN with OP_PIN_ITEM
- `getpin-pinentry-user-data` - GETPIN with PINENTRY_USER_DATA (takes precedence)
- `getpin-no-config` - Error when no config set
- `set-commands` - SET* commands return OK
- `option-command` - OPTION command handling
- `reset-command` - RESET command clears state
- `getpin-failure` - GETPIN failure error handling
- `confirm-command` - CONFIRM auto-confirms

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
