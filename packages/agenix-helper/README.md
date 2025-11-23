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
3. The decrypted key is stored temporarily at `/tmp/id_age` with `600` permissions (owner read/write only)
4. The `.envrc` automatically exports environment variables pointing to the unlocked key
5. All subsequent agenix operations use the unlocked key without prompting
6. When done, run `agenix-helper lock` to remove the decrypted key

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
# 🔓 Age identity unlocked at /tmp/id_age

# Now work with secrets normally - no more passphrase prompts!
agenix edit secrets/nixos/pilaster/my-secret.age
agenix rekey -a
agenix edit secrets/nixos/framework/another-secret.age

# When done for the day
agenix-helper lock
# 🔒 Age identity locked (removed /tmp/id_age)
```

### Integration with direnv

When used with the included `.envrc` integration:

```bash
cd ~/Projects/nix-config
# direnv: loading ~/Projects/nix-config/.envrc
# ⚠️  Age identity not unlocked. Run 'agenix-helper unlock' to unlock manually.

agenix-helper unlock
# 🔓 Age identity unlocked at /tmp/id_age

# Environment variables are automatically set:
echo $SOPS_AGE_KEY_FILE     # /tmp/id_age
echo $AGE_IDENTITIES_FILE   # /tmp/id_age
```

## Environment Variables

Customize behavior with these environment variables:

- `AGE_IDENTITY_FILE` - Path to decrypted identity (default: `/tmp/id_age`)
- `AGE_IDENTITY_ENCRYPTED` - Path to encrypted identity (default: `secrets/id_age.age`)
- `AGE_IDENTITY_BACKUP` - Path to backup identity (default: `/tmp/id_age_`)

## Security Considerations

### Secure Storage
- Decrypted key stored at `/tmp/id_age` with `600` permissions (owner read/write only)
- `/tmp` is typically cleared on system reboot
- Old identity backed up to `/tmp/id_age_` when unlocking again

### Best Practices
1. **Lock when done**: Always run `agenix-helper lock` when finished working with secrets
2. **System reboot**: The unlocked key is automatically cleared on reboot
3. **Shared systems**: Don't use this on multi-user systems where others have root access
4. **Screen lock**: Lock your screen when stepping away from your workstation
5. **Review habits**: Consider your threat model - if you need maximum security, enter the passphrase for each operation instead

### What This Doesn't Protect Against
- Root users on the same system (they can read `/tmp/id_age`)
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

- `age` - Age encryption tool
- `coreutils` - Basic Unix utilities (for mv, chmod, etc.)

## Implementation Details

### Quiet Mode
In quiet mode (`agenix-helper unlock quiet`):
- Checks if `/tmp/id_age` already exists
- If yes, returns success immediately (exit code 0)
- If no, returns failure silently (exit code 1)
- Never prompts for passphrase

This is designed for use in `.envrc` and other automated contexts where you don't want interactive prompts.

### Interactive Mode
In interactive mode (`agenix-helper unlock`):
- Prompts for passphrase if key not already unlocked
- Displays success/error messages
- Returns exit code 0 on success, 1 on failure

## Version

**0.1.0** - Initial release

## License

MIT

## See Also

- [agenix](https://github.com/ryantm/agenix) - Age encryption for NixOS
- [agenix-rekey](https://github.com/oddlama/agenix-rekey) - Rekeying support for agenix
- [age](https://age-encryption.org/) - Modern encryption tool
