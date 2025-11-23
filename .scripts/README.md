# Scripts Directory

Helper scripts for the nix-config repository.

## agenix-unlock.sh

Simplifies working with passphrase-protected age identities by providing convenient unlock/lock commands.

### Background

This setup is inspired by [suderman/nixos](https://github.com/suderman/nixos/blob/main/packages/agenix/agenix.sh), which provides a streamlined workflow for managing encrypted age keys.

### How It Works

1. Your age identity is stored encrypted at `secrets/id_age.age`
2. When you need to work with agenix secrets, unlock the identity once
3. The decrypted key is stored temporarily at `/tmp/id_age` with `600` permissions
4. All subsequent agenix operations use this unlocked key
5. When done, lock the identity to remove the decrypted key

### Usage

The script is integrated with direnv and provides three commands via shell aliases:

```bash
# Unlock the age identity (prompts for passphrase)
age-unlock

# Check if the identity is currently unlocked
age-status

# Lock the identity (remove decrypted key)
age-lock
```

### Direnv Integration

When you `cd` into the nix-config directory:
- direnv automatically checks if the age identity is unlocked
- If unlocked, it exports `SOPS_AGE_KEY_FILE` and `AGE_IDENTITIES_FILE` environment variables
- If not unlocked, you'll see a helpful message prompting you to run `age-unlock`

This means you only need to unlock once per session, rather than entering your passphrase for every agenix operation.

### Security Notes

- The decrypted key is stored in `/tmp/id_age` with `600` permissions (owner read/write only)
- `/tmp` is typically cleared on system reboot
- Remember to run `age-lock` when you're done working with secrets
- The unlock operation only works in interactive mode - it won't prompt for passphrases in scripts

### Environment Variables

You can customize the behavior using these environment variables:

- `AGE_IDENTITY_FILE` - Path to decrypted identity (default: `/tmp/id_age`)
- `AGE_IDENTITY_ENCRYPTED` - Path to encrypted identity (default: `secrets/id_age.age`)
- `AGE_IDENTITY_BACKUP` - Path to backup identity (default: `/tmp/id_age_`)
