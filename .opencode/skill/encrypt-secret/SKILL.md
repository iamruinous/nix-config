---
name: encrypt-secret
description: Create or update an encrypted .age secret file using agenix
compatibility: Requires agenix, agenix-helper
metadata:
  author: ruinous.ai
  version: "1.1"
  domain: secrets
parameters:
  secret_path:
    type: string
    description: Path to the .age secret file to create/update
    required: true
    placeholder: "hosts/pilaster/files/docker/env/myapp.env.age"
  input_file:
    type: string
    description: Optional path to plaintext input file
    required: false
    placeholder: "/tmp/secret.txt"
---

# Encrypt Secret

Create or update an encrypted `.age` secret file using agenix.

## Parameter Handling

**If `secret_path` is missing from `$ARGUMENTS`, use `mcp_question` to gather it:**

```
mcp_question({
  questions: [
    {
      question: "What is the path for the secret file?",
      header: "Secret Path",
      options: [
        { label: "Docker env file", description: "hosts/<host>/files/docker/env/<service>.env.age" },
        { label: "Caddyfile", description: "hosts/<host>/files/caddy/Caddyfile.age" },
        { label: "Cloudflared cert", description: "hosts/<host>/files/cloudflared/cert.pem.age" },
        { label: "Enter custom path...", description: "Specify a custom path" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<secret_path> [input_file]`
- Example: `hosts/pilaster/files/docker/env/myapp.env.age`
- Example with input: `hosts/pilaster/files/docker/env/myapp.env.age /tmp/secret.txt`

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
