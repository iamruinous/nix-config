---
name: encrypt-secret
description: Create or update an encrypted .age secret file using agenix
compatibility: Requires agenix, agenix-helper
metadata:
  author: ruinous.ai
  version: "1.0"
  domain: secrets
---

# Encrypt Secret

Create or update an encrypted `.age` secret file using agenix.

**Arguments:** `$ARGUMENTS` should contain:
- Path to the secret file (e.g., `hosts/pilaster/files/docker/env/myapp.env.age`)
- Optionally: path to plaintext input file

## Prerequisites

```bash
# Unlock agenix before working with secrets
agenix-helper unlock
```

## Steps

### Creating a New Secret

1. **Create the directory structure:**
   ```bash
   mkdir -p hosts/<hostname>/files/docker/env
   ```

2. **Create plaintext content** in `/tmp/`:
   ```bash
   cat > /tmp/secret.txt << 'EOF'
   SECRET_KEY=value
   API_TOKEN=value
   EOF
   ```

3. **Encrypt the file:**
   ```bash
   agenix edit -i /tmp/secret.txt <output-path>.age
   ```

4. **Clean up plaintext:**
   ```bash
   rm /tmp/secret.txt
   ```

5. **Rekey all secrets:**
   ```bash
   agenix rekey -a
   ```

### Updating an Existing Secret

1. **Export current content:**
   ```bash
   agenix view <path>.age > /tmp/secret.txt
   ```

2. **Edit the temporary file** (add/modify values)

3. **Remove old encrypted file:**
   ```bash
   rm <path>.age
   ```

4. **Re-encrypt:**
   ```bash
   agenix edit -i /tmp/secret.txt <path>.age
   ```

5. **Clean up and rekey:**
   ```bash
   rm /tmp/secret.txt
   agenix rekey -a
   ```

## Secret File Locations

| Purpose | Path Pattern |
|---------|-------------|
| Caddyfiles | `hosts/<hostname>/files/caddy/Caddyfile.age` |
| Docker env | `hosts/<hostname>/files/docker/env/<service>.env.age` |
| Cloudflared certs | `hosts/<hostname>/files/cloudflared/cert.pem.age` |
| Cloudflared tunnels | `hosts/<hostname>/files/cloudflared/<tunnel>.json.age` |

## Nix Integration

Add to the host's configuration:

```nix
age.secrets.<hostname>_docker_env_<service> = {
  rekeyFile = ./files/docker/env/<service>.env.age;
  mode = "600";
};
```

## Example

```bash
# Create new Docker env secret
/encrypt-secret hosts/pilaster/files/docker/env/myapp.env.age

# Update existing Caddyfile
/encrypt-secret hosts/monolith/files/caddy/Caddyfile.age
```

## Post-Encryption Checklist

- [ ] Ran `agenix rekey -a`
- [ ] Removed plaintext temporary files
- [ ] Added `age.secrets.*` entry to Nix config
- [ ] Ran `agenix-helper lock` when done
