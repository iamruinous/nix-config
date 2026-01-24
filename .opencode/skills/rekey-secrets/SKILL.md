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
agenix-helper unlock
```

## Steps

1. **Rekey all secrets:**
   ```bash
   agenix rekey -a
   ```

2. **Verify rekeyed files:**
   ```bash
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
agenix-helper unlock
```

## Example

```bash
# After updating any secret
/rekey-secrets
```

## Post-Rekey Checklist

- [ ] All secrets rekeyed successfully
- [ ] `secrets/nixos/` contains updated files
- [ ] No errors in output
- [ ] Ran `agenix-helper lock`
