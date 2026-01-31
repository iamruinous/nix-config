---
name: encrypt-secret
description: Create or update secrets using Infisical (preferred) or legacy agenix files
compatibility: Requires infisical CLI, agenix, agenix-helper
metadata:
  author: ruinous.ai
  version: "2.0"
  domain: secrets
parameters:
  secret_name:
    type: string
    description: Name of the secret (e.g., GITHUB_WEBHOOK_SECRET)
    required: true
    placeholder: "MY_SECRET_NAME"
  secret_path:
    type: string
    description: Infisical path (e.g., /shared, /moltbot) or legacy .age file path
    required: true
    placeholder: "/shared"
  secret_value:
    type: string
    description: The secret value (or 'generate' for random hex)
    required: false
    placeholder: "generate"
  mode:
    type: string
    description: infisical (default) or legacy
    required: false
    default: "infisical"
---

# Encrypt Secret

Create or update secrets using **Infisical** (preferred) or legacy agenix file encryption.

## Quick Reference

| Property | Value |
|----------|-------|
| **Infisical API** | `https://infisical.meskill.farm` |
| **Project ID** | `f95d3144-22bb-4c95-9ee8-f3319d4924d5` |
| **Environment** | `homelab` |

## Parameter Handling

**If parameters are missing, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "What type of secret are you creating?",
      header: "Secret Type",
      options: [
        { label: "Infisical (Recommended)", description: "Store in centralized Infisical, generate .age via mkGenerator" },
        { label: "Legacy agenix file", description: "Direct .age encryption for binary files (certs, keys)" }
      ]
    }
  ]
})
```

For Infisical secrets, also ask:
```
mcp_question({
  questions: [
    {
      question: "What Infisical path should this secret be stored at?",
      header: "Secret Path",
      options: [
        { label: "/shared", description: "Cross-service secrets (tokens, API keys used by multiple services)" },
        { label: "/moltbot", description: "Moltbot service secrets" },
        { label: "/opencode", description: "OpenCode service secrets" },
        { label: "/caddy", description: "Caddy/proxy secrets" },
        { label: "/budgey", description: "Budgey service secrets" }
      ]
    },
    {
      question: "What is the secret name?",
      header: "Secret Name",
      options: []  // Free text input
    },
    {
      question: "How should the value be set?",
      header: "Secret Value",
      options: [
        { label: "Generate random (64 hex chars)", description: "openssl rand -hex 32" },
        { label: "Generate random (32 hex chars)", description: "openssl rand -hex 16" },
        { label: "Enter value manually", description: "You will provide the value" }
      ]
    }
  ]
})
```

## Infisical Workflow (Recommended)

### Prerequisites

```bash
# Login to Infisical (interactive)
infisical login --domain https://infisical.meskill.farm

# Or set token
export INFISICAL_TOKEN="your-token"
```

### Step 1: Create Secret in Infisical

```bash
PROJECT_ID="f95d3144-22bb-4c95-9ee8-f3319d4924d5"

# Generate random value if needed
SECRET_VALUE=$(openssl rand -hex 32)

# Create the secret
infisical secrets set SECRET_NAME="$SECRET_VALUE" \
  --env=homelab \
  --path=/shared \
  --projectId=$PROJECT_ID
```

### Step 2: Add Nix Configuration

Add to the appropriate host configuration:

```nix
# Enable Infisical integration (if not already)
ruinous.infisical.enable = true;

# Define the secret with mkGenerator
age.secrets.<host>_<service>_<secret_name> = {
  generator.script = config.ruinous.infisical.mkGenerator {
    name = "SECRET_NAME";
    path = "/shared";  # or /moltbot, /opencode, etc.
  };
  mode = "400";
  # owner = "service-user";  # if needed
};
```

### Step 3: Generate and Rekey

```bash
# Generate secrets from Infisical
agenix generate -a

# Rekey for all hosts
agenix rekey -a

# Stage the generated files
git add secrets/
```

### Step 4: Verify

```bash
# Check build passes
just check <host>

# View the secret (after deployment)
# cat /run/agenix/<secret_name>
```

## Infisical Path Structure

| Path | Purpose | Examples |
|------|---------|----------|
| `/shared` | Cross-service secrets | GITHUB_TOKEN, ANTHROPIC_API_KEY |
| `/moltbot` | Moltbot Discord bot | DISCORD_TOKEN, GATEWAY_TOKEN |
| `/opencode` | OpenCode services | API keys, project tokens |
| `/caddy` | Reverse proxy | CLOUDFLARE_API_TOKEN |
| `/budgey` | Budgey assistant | DB_PASSWORD, DEPLOY_KEY |
| `/forgejo` | Forgejo/Git services | WEBHOOK_SECRET, API_TOKEN |

## Common Infisical Commands

```bash
PROJECT_ID="f95d3144-22bb-4c95-9ee8-f3319d4924d5"

# List secrets at path
infisical secrets --env=homelab --path=/shared --projectId=$PROJECT_ID

# Get single secret value
infisical secrets get SECRET_NAME --env=homelab --path=/shared \
  --projectId=$PROJECT_ID --plain

# Update existing secret
infisical secrets set SECRET_NAME="new-value" --env=homelab --path=/shared \
  --projectId=$PROJECT_ID

# Delete secret
infisical secrets delete SECRET_NAME --env=homelab --path=/shared \
  --projectId=$PROJECT_ID

# Create folder
infisical secrets folders create --name=newfolder --env=homelab --path=/ \
  --projectId=$PROJECT_ID
```

## Secret References (Aliases)

Infisical supports references to avoid duplication:

```bash
# Create alias in same path
infisical secrets set 'GITHUB_ACCESS_TOKEN=${GITHUB_TOKEN}' \
  --env=homelab --path=/shared --projectId=$PROJECT_ID

# Reference from /shared in service path
infisical secrets set 'GITHUB_TOKEN=${shared.GITHUB_TOKEN}' \
  --env=homelab --path=/moltbot --projectId=$PROJECT_ID
```

---

## Legacy Agenix Workflow

Use for binary files (certificates, SSH keys) that can't be stored as text in Infisical.

### Prerequisites

```bash
# Unlock agenix identity
agenix-helper unlock
```

### Creating a New Legacy Secret

1. **Create directory structure:**
   ```bash
   mkdir -p hosts/<hostname>/files/docker/env
   ```

2. **Create plaintext content:**
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

4. **Clean up and rekey:**
   ```bash
   rm /tmp/secret.txt
   agenix rekey -a
   ```

### Legacy Nix Integration

```nix
age.secrets.<hostname>_<service>_<name> = {
  rekeyFile = ./files/docker/env/<service>.env.age;
  mode = "600";
};
```

### Legacy File Locations

| Purpose | Path Pattern |
|---------|-------------|
| Docker env | `hosts/<host>/files/docker/env/<service>.env.age` |
| Caddyfiles | `hosts/<host>/files/caddy/Caddyfile.age` |
| Cloudflared certs | `hosts/<host>/files/cloudflared/cert.pem.age` |
| Cloudflared tunnels | `hosts/<host>/files/cloudflared/<tunnel>.json.age` |

---

## Decision Guide: Infisical vs Legacy

| Use Infisical When | Use Legacy When |
|--------------------|-----------------|
| Text-based secrets (tokens, passwords, API keys) | Binary files (certificates, SSH keys) |
| Secrets shared across hosts | Host-specific file structures |
| Secrets that change frequently | Static credentials |
| Secrets you want to manage via UI | Secrets tightly coupled to file paths |

---

## Example: Creating a Webhook Secret

```bash
# 1. Generate and store in Infisical
PROJECT_ID="f95d3144-22bb-4c95-9ee8-f3319d4924d5"
WEBHOOK_SECRET=$(openssl rand -hex 32)

infisical secrets set GITHUB_FORGE_WEBHOOK_SECRET="$WEBHOOK_SECRET" \
  --env=homelab --path=/shared --projectId=$PROJECT_ID

# 2. Add to Nix config (e.g., hosts/monolith/webhooks.nix)
# age.secrets.monolith_github_webhook_secret = {
#   generator.script = config.ruinous.infisical.mkGenerator {
#     name = "GITHUB_FORGE_WEBHOOK_SECRET";
#     path = "/shared";
#   };
#   mode = "400";
# };

# 3. Generate and rekey
agenix generate -a
agenix rekey -a
git add secrets/

# 4. Verify
just check monolith
```

## Post-Creation Checklist

### Infisical Secrets
- [ ] Secret created in Infisical at correct path
- [ ] Nix config uses `mkGenerator` with correct name/path
- [ ] Ran `agenix generate -a`
- [ ] Ran `agenix rekey -a`
- [ ] Staged secrets/ changes
- [ ] Build passes (`just check <host>`)

### Legacy Secrets
- [ ] Plaintext file removed
- [ ] Ran `agenix rekey -a`
- [ ] Added `age.secrets.*` entry to Nix config
- [ ] Ran `agenix-helper lock` when done
