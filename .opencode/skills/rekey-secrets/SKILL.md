---
name: rekey-secrets
description: Re-encrypt all secrets after modifying .age files or changing host keys
compatibility: Requires agenix, agenix-helper
metadata:
  author: ruinous.ai
  version: "1.0"
  domain: secrets
---

# Rekey Secrets

Re-encrypt all secrets after modifying `.age` files or when host keys change.

**When to use:**
- After creating or updating any `.age` file
- After adding a new host to `secrets.nix`
- After rotating host SSH keys

## Prerequisites

```bash
# Unlock agenix before rekeying
just unlock
```

## Steps

1. **Rekey all secrets:**
   ```bash
   just rekey
   ```

2. **Stage and verify rekeyed files:**
   ```bash
   git add secrets/
   ls secrets/nixos/*/
   ```

3. **Lock agenix when done:**
   ```bash
   agenix-helper lock
   ```

## Where Rekeyed Secrets Go

After `agenix rekey -a`, encrypted secrets are stored in:
```
secrets/nixos/<hostname>/<hash>-<secret_name>.age
```

## Troubleshooting

### Rekey fails with host errors
- Check that all hosts in `secrets.nix` have valid keys
- Verify host public keys are correct in the repository

### Permission denied
```bash
# Ensure agenix is unlocked
just unlock
```

## Example

```bash
# Unlock, rekey, and stage
just unlock
just rekey
git add secrets/
```

## Post-Rekey Checklist

- [ ] Ran `just unlock` before starting
- [ ] All secrets rekeyed successfully (`just rekey`)
- [ ] `secrets/nixos/` contains updated files
- [ ] Staged changes (`git add secrets/`)
- [ ] No errors in output
- [ ] Ran `agenix-helper lock` when done
