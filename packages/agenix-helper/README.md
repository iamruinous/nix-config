# agenix-helper

Helper utility for managing passphrase-protected age identities with agenix.

## Purpose

Simplifies working with encrypted age identities by providing a convenient unlock/lock workflow. Instead of entering your passphrase for every agenix operation, you can unlock your identity once per session and reuse the decrypted key for all subsequent operations.

This dramatically improves the developer experience when working with encrypted secrets, especially during iterative workflows like editing multiple secrets or running `agenix rekey` operations.

## Background

This implementation is inspired by [suderman/nixos](https://github.com/suderman/nixos/blob/main/packages/agenix/agenix.sh), which provides a streamlined workflow for managing encrypted age keys.

## How It Works

1. Your age identity is stored encrypted at `secrets/id_age.age`
2. When you run `agenix-helper unlock`, it prompts for your passphrase
3. The decrypted **host identity** is stored at `~/.local/state/agenix-helper/host_id_age` with `600` permissions
4. The decrypted **user identity** (for home-manager agenix) is stored at `~/.config/age/user_id_age`
5. The `.envrc` automatically exports environment variables pointing to the unlocked key
6. All subsequent agenix operations use the unlocked key without prompting
7. When done, run `agenix-helper lock` to remove the decrypted keys

## Usage

### Commands

```bash
# Unlock the age identity (prompts for passphrase)
agenix-helper unlock
# or short form
agenix-helper u

# Check if the identity is currently unlocked
agenix-helper status
# or short form
agenix-helper s

# Lock the identity (remove decrypted key)
agenix-helper lock
# or short form
agenix-helper l

# Quiet mode (for scripting, doesn't prompt)
agenix-helper unlock quiet
```

### Typical Workflow

```bash
# Enter your project directory
cd ~/Projects/nix-config

# Unlock once at the start of your session
agenix-helper unlock
# Enter passphrase: ********
# 🔓 Host identity unlocked at ~/.local/state/agenix-helper/host_id_age
# 🔓 User identity unlocked at ~/.config/age/user_id_age

# Now work with secrets normally - no more passphrase prompts!
agenix edit secrets/nixos/pilaster/my-secret.age
agenix rekey -a
agenix edit secrets/nixos/framework/another-secret.age

# When done for the day
agenix-helper lock
# 🔒 Agenix identities locked and removed
```

### Integration with direnv

When used with the included `.envrc` integration:

```bash
cd ~/Projects/nix-config
# direnv: loading ~/Projects/nix-config/.envrc
# ⚠️  Age identity not unlocked. Run 'agenix-helper unlock' to unlock manually.

agenix-helper unlock
# 🔓 Host identity unlocked at ~/.local/state/agenix-helper/host_id_age
# 🔓 User identity unlocked at ~/.config/age/user_id_age

# Environment variables are automatically set:
echo $SOPS_AGE_KEY_FILE     # ~/.local/state/agenix-helper/host_id_age
echo $AGE_IDENTITIES_FILE   # ~/.local/state/agenix-helper/host_id_age
```

## 1Password Integration

If you have the [1Password CLI (`op`)](https://developer.1password.com/docs/cli) installed and configured, `agenix-helper` can automatically retrieve passphrases from 1Password instead of prompting interactively.

This integration uses the [`pinentry-1password`](../pinentry-1password/README.md) package, which implements the standard pinentry protocol that `rage` natively supports via the `PINENTRY_PROGRAM` environment variable.

### Requirements

1. Install and configure 1Password CLI (`op`)
2. Install `pinentry-1password` package
3. Be signed in to 1Password (`op signin` or biometric unlock)

### Setup

```bash
# Set the 1Password secret references (in your shell config or .envrc)
# Default: These values are used if you haven't set custom values
export AGENIX_HELPER_OP_HOST_SECRET="${AGENIX_HELPER_OP_HOST_SECRET:-op://Private/agenix-helper-unlock/host-passphrase}"
export AGENIX_HELPER_OP_USER_SECRET="${AGENIX_HELPER_OP_USER_SECRET:-op://Private/agenix-helper-unlock/user-passphrase}"
# Override with your custom values if needed:
# export AGENIX_HELPER_OP_HOST_SECRET="op://your-custom-host-passphrase"
# export AGENIX_HELPER_OP_USER_SECRET="op://your-custom-user-passphrase"
```

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `AGENIX_HELPER_OP_HOST_SECRET` | 1Password reference for host identity passphrase (`secrets/id_age.age`) |
| `AGENIX_HELPER_OP_USER_SECRET` | 1Password reference for user identity passphrase (`users/$USER/id_age.age`) |

### How It Works

When you run `agenix-helper unlock`:
1. Checks if `op` command and `pinentry-1password` are available
2. If `AGENIX_HELPER_OP_HOST_SECRET` is set:
   - Sets `OP_PIN_ITEM` to the secret reference
   - Sets `PINENTRY_PROGRAM=pinentry-1password`
   - Calls `rage -d` which delegates passphrase retrieval to pinentry-1password
   - pinentry-1password uses `op read $OP_PIN_ITEM` to fetch the passphrase
3. Falls back to interactive prompt if 1Password integration is unavailable
4. Same process for user identity using `AGENIX_HELPER_OP_USER_SECRET`

### 1Password Secret Reference Format

References should be in the format: `op://vault/item/field`

Examples:
- `op://Private/age-host-identity/passphrase`
- `op://Work/nixos-secrets/host-passphrase`
- `op://Personal/encryption-keys/user-passphrase`

### Benefits

- No need to remember or type passphrases
- Works seamlessly with 1Password's biometric unlock
- Supports separate passphrases for host and user identities
- Uses standard pinentry protocol (native rage support)
- Still secure (passphrases never stored on disk)
- Falls back to interactive prompt if 1Password is unavailable

### Debugging

If 1Password integration isn't working, enable debug logging:

```bash
AGENIX_HELPER_DEBUG=1 agenix-helper unlock
```

This will show which code paths are taken and help identify the issue.

## Environment Variables

Customize behavior with these environment variables:

### Path Configuration
- `AGE_IDENTITY_DIR` - Directory for host identity files (default: `~/.local/state/agenix-helper`)
- `AGE_IDENTITY_FILE` - Path to decrypted host identity (default: `$AGE_IDENTITY_DIR/host_id_age`)
- `AGE_IDENTITY_ENCRYPTED` - Path to encrypted host identity (default: `secrets/id_age.age`)
- `AGE_IDENTITY_BACKUP` - Path to backup host identity (default: `$AGE_IDENTITY_DIR/host_id_age_`)
- `AGE_USER_IDENTITY_FILE` - Path to decrypted user identity (default: `~/.config/age/user_id_age`)
- `AGE_USER_IDENTITY_ENCRYPTED` - Path to encrypted user identity (default: `users/$USER/id_age.age`)

### 1Password Integration
- `OP_PIN_ITEM` - 1Password reference for age identity passphrase (used by pinentry-1password)

## Security Considerations

### Secure Storage
- Host identity stored at `~/.local/state/agenix-helper/host_id_age` with `600` permissions (owner read/write only)
- User identity stored at `~/.config/age/user_id_age` with `600` permissions
- Directory `~/.local/state/agenix-helper/` created with `700` permissions
- Old identity backed up when unlocking again

### Best Practices
1. **Lock when done**: Always run `agenix-helper lock` when finished working with secrets
2. **Shared systems**: Don't use this on multi-user systems where others have root access
3. **Screen lock**: Lock your screen when stepping away from your workstation
4. **Review habits**: Consider your threat model - if you need maximum security, enter the passphrase for each operation instead

### What This Doesn't Protect Against
- Root users on the same system (they can read your home directory)
- Physical access to your unlocked system
- Memory dumps or forensics while the key is unlocked

## Installation

The package is automatically available through the overlay in this flake. To install on a NixOS system:

```nix
# In your configuration.nix
environment.systemPackages = with pkgs; [
  agenix-helper
];
```

Or in home-manager:

```nix
home.packages = with pkgs; [
  agenix-helper
];
```

## Dependencies

- `rage` - Rust version of age encryption tool (supports PINENTRY_PROGRAM)
- `gum` - Terminal UI components
- `coreutils` - Basic Unix utilities (for mv, chmod, etc.)

### Optional (for 1Password integration)
- `pinentry-1password` - Pinentry implementation using 1Password CLI
- `op` - 1Password CLI

## Implementation Details

### Two Identity Files

agenix-helper manages two separate identity files:

1. **Host Identity** (`~/.local/state/agenix-helper/host_id_age`)
   - Used for `agenix-rekey` operations (rekeying secrets for hosts)
   - Decrypted from `secrets/id_age.age` using your passphrase
   - Symlinked to `/tmp/host_id_age` for agenix-rekey compatibility (see below)

2. **User Identity** (`~/.config/age/user_id_age`)
   - Used by home-manager's agenix module for runtime secret decryption
   - Decrypted from `users/$USER/id_age.age` using the host identity
   - Allows systemd user services to decrypt secrets at runtime

### Quiet Mode
In quiet mode (`agenix-helper unlock quiet`):
- Checks if `~/.local/state/agenix-helper/host_id_age` already exists
- If yes, returns success immediately (exit code 0)
- If no, returns failure silently (exit code 1)
- Never prompts for passphrase

This is designed for use in `.envrc` and other automated contexts where you don't want interactive prompts.

### Interactive Mode
In interactive mode (`agenix-helper unlock`):
- Prompts for passphrase if key not already unlocked
- Displays success/error messages
- Returns exit code 0 on success, 1 on failure

### Why /tmp Symlinks?

agenix-rekey evaluates ALL host configurations to collect their `masterIdentities` paths. If we used user-specific paths like `/home/$USER/.local/state/agenix-helper/host_id_age`, agenix would try to access paths for other users (git, messy, root) and fail with "Permission denied" or "No such file" errors.

The solution is to use static `/tmp` paths that all configurations reference:
- `agenix-helper unlock` creates symlinks: `/tmp/host_id_age` → `~/.local/state/agenix-helper/host_id_age`
- `secrets/default.nix` uses `masterIdentities = ["/tmp/host_id_age" "/tmp/host_id_age_"]`
- All host configurations evaluate to the same paths, avoiding permission issues

## Version

**0.1.0** - Initial release

## License

MIT

## See Also

- [agenix](https://github.com/ryantm/agenix) - Age encryption for NixOS
- [agenix-rekey](https://github.com/oddlama/agenix-rekey) - Rekeying support for agenix
- [rage](https://github.com/str4d/rage) - Rust implementation of age: modern encryption tool
