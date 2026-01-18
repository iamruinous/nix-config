---
name: view-secret
description: Decrypt and view the contents of an .age secret file
compatibility: Requires agenix, agenix-helper
metadata:
  author: ruinous.ai
  version: "1.0"
  domain: secrets
---

# View Secret

Decrypt and view the contents of an encrypted `.age` secret file.

**Arguments:** `$ARGUMENTS` should contain the path to the .age file

## Prerequisites

```bash
# Unlock agenix before viewing secrets
agenix-helper unlock
```

## Steps

1. **View a single secret:**
   ```bash
   agenix view <path>.age
   ```

2. **View all secrets for a host:**
   ```bash
   for f in hosts/<hostname>/files/**/*.age; do
     echo "=== $f ==="
     agenix view "$f"
     echo
   done
   ```

3. **Export to temporary file for editing:**
   ```bash
   agenix view <path>.age > /tmp/secret.txt
   ```

## Example

```bash
# View a Docker environment file
/view-secret hosts/pilaster/files/docker/env/n8n.env.age

# View a Caddyfile
/view-secret hosts/monolith/files/caddy/Caddyfile.age
```

## Common Secret Locations

| Type | Path |
|------|------|
| Docker env | `hosts/<host>/files/docker/env/*.env.age` |
| Caddyfile | `hosts/<host>/files/caddy/Caddyfile.age` |
| Cloudflared | `hosts/<host>/files/cloudflared/*.age` |

## Security Notes

- Never pipe secret contents to files outside `/tmp/`
- Clean up any exported files after use
- Run `agenix-helper lock` when finished with secrets work
