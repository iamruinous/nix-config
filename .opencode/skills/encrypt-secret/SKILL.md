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
    description: Infisical path (e.g., /shared, /services/openclaw, /hosts/chassis/openclaw)
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
      question: "Is this secret used by multiple different services?",
      header: "Secret Scope",
      options: [
        { label: "Yes - shared across services", description: "Same value used by openclaw, n8n, opencode, etc. → /shared/" },
        { label: "No - one service only", description: "Dedicated to a single service → /services/ or /hosts/" }
      ]
    }
  ]
})

// If service-specific, follow up:
mcp_question({
  questions: [
    {
      question: "Is this secret the same across all hosts running this service?",
      header: "Host Scope",
      options: [
        { label: "Yes - service-wide", description: "Same on any host running the service → /services/<service>/" },
        { label: "No - host-specific", description: "Different per host instance → /hosts/<host>/<service>/" }
      ]
    }
  ]
})
```

Then ask for the specific path components:
```
mcp_question({
  questions: [
    {
      question: "What is the service name?",
      header: "Service Name",
      options: [
        { label: "openclaw", description: "OpenClaw/Moltbot AI assistant" },
        { label: "opencode", description: "OpenCode AI coding services" },
        { label: "budgey", description: "Budgey finance assistant" },
        { label: "caddy", description: "Caddy reverse proxy" },
        { label: "n8n", description: "n8n workflow automation" }
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
# Unlock agenix identity first (enter passphrase once per session)
just unlock

# Login to Infisical (interactive) if not already
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

# Shared secret (used by multiple services)
age.secrets.<host>_<service>_<secret_name> = {
  generator.script = config.ruinous.infisical.mkGenerator {
    name = "GITHUB_TOKEN";
    path = "/shared";
  };
  mode = "400";
};

# Service-specific secret (not host-specific)
age.secrets.<host>_openclaw_openai_key = {
  generator.script = config.ruinous.infisical.mkGenerator {
    name = "OPENAI_API_KEY";
    path = "/services/openclaw";
  };
  mode = "400";
  owner = "jmeskill";
};

# Host-specific secret
age.secrets.chassis_openclaw_discord_token = {
  generator.script = config.ruinous.infisical.mkGenerator {
    name = "DISCORD_TOKEN";
    path = "/hosts/chassis/openclaw";
  };
  mode = "400";
  owner = "jmeskill";
};
```

### Step 3: Generate and Rekey

```bash
# Generate secrets from Infisical
agenix generate -a

# Rekey for all hosts
just rekey

# Stage the generated files
git add secrets/
```

### Step 4: Verify and Deploy

```bash
# Check build passes
just check <host>

# Deploy changes
just deploy <host>

# View the secret (after deployment)
# cat /run/agenix/<secret_name>
```

## Infisical Path Structure

### Three-Tier Hierarchy

```
/
├── shared/                        # Cross-service secrets (same value everywhere)
│   ├── GITHUB_TOKEN
│   ├── ANTHROPIC_API_KEY
│   └── CLOUDFLARE_API_TOKEN
│
├── services/                      # Service-specific, NOT host-specific
│   ├── openclaw/
│   │   └── OPENAI_API_KEY        # OpenClaw's dedicated key
│   ├── budgey/
│   │   └── DATABASE_URL
│   └── opencode/
│       └── PROJECT_TOKEN
│
├── hosts/                         # Host-specific service instances
│   ├── chassis/
│   │   ├── openclaw/
│   │   │   └── DISCORD_TOKEN
│   │   └── caddy/
│   │       └── BASIC_AUTH_HASH
│   ├── monolith/
│   │   └── ...
│   └── ...
│
└── nixos/                         # LEGACY - being migrated
```

### Decision Flow

```
Is this secret used by multiple different services?
├─ YES → /shared/
└─ NO → Is this secret the same across all hosts running this service?
         ├─ YES → /services/<service>/
         └─ NO → /hosts/<host>/<service>/
```

### Path Reference

| Path | Purpose | Examples |
|------|---------|----------|
| `/shared/` | Same value used by MULTIPLE services | GITHUB_TOKEN, ANTHROPIC_API_KEY, CLOUDFLARE_API_TOKEN |
| `/services/<service>/` | Service-specific, any host | `/services/openclaw/OPENAI_API_KEY`, `/services/budgey/DATABASE_URL` |
| `/hosts/<host>/<service>/` | Host-specific instance | `/hosts/chassis/openclaw/DISCORD_TOKEN` |

### When to Use Each

| Use `/shared/` | Use `/services/<service>/` | Use `/hosts/<host>/<service>/` |
|----------------|---------------------------|-------------------------------|
| Same API account for all | Isolated quota/billing per service | Different per host instance |
| GITHUB_TOKEN for all tools | Service needs own rate limits | Discord bot per host |
| Shared Cloudflare account | Rotate independently | Host-specific auth |

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

# Reference /shared secret from a service path
infisical secrets set 'ANTHROPIC_API_KEY=${shared.ANTHROPIC_API_KEY}' \
  --env=homelab --path=/services/openclaw --projectId=$PROJECT_ID

# Reference /shared secret from a host-specific path
infisical secrets set 'GITHUB_TOKEN=${shared.GITHUB_TOKEN}' \
  --env=homelab --path=/hosts/chassis/openclaw --projectId=$PROJECT_ID
```

---

## Legacy Agenix Workflow

Use for binary files (certificates, SSH keys) that can't be stored as text in Infisical.

### Prerequisites

```bash
# Unlock agenix identity
just unlock
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
   just encrypt <output-path>.age
   # Or with input file:
   agenix edit -i /tmp/secret.txt <output-path>.age
   ```

4. **Clean up and rekey:**
   ```bash
   rm /tmp/secret.txt
   just rekey
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
# 1. Unlock agenix identity
just unlock

# 2. Generate and store in Infisical
PROJECT_ID="f95d3144-22bb-4c95-9ee8-f3319d4924d5"
WEBHOOK_SECRET=$(openssl rand -hex 32)

infisical secrets set GITHUB_FORGE_WEBHOOK_SECRET="$WEBHOOK_SECRET" \
  --env=homelab --path=/shared --projectId=$PROJECT_ID

# 3. Add to Nix config (e.g., hosts/monolith/webhooks.nix)
# age.secrets.monolith_github_webhook_secret = {
#   generator.script = config.ruinous.infisical.mkGenerator {
#     name = "GITHUB_FORGE_WEBHOOK_SECRET";
#     path = "/shared";
#   };
#   mode = "400";
# };

# 4. Generate and rekey
agenix generate -a
just rekey
git add secrets/

# 5. Verify and deploy
just check monolith
just deploy monolith
```

## Post-Creation Checklist

### Infisical Secrets
- [ ] Ran `just unlock` before starting
- [ ] Secret created in Infisical at correct path (see Three-Tier Hierarchy)
- [ ] Nix config uses `mkGenerator` with correct name/path
- [ ] Ran `agenix generate -a`
- [ ] Ran `just rekey`
- [ ] Staged secrets/ changes (`git add secrets/`)
- [ ] Build passes (`just check <host>`)
- [ ] Deployed (`just deploy <host>`)

### Legacy Secrets
- [ ] Ran `just unlock` before starting
- [ ] Plaintext file removed
- [ ] Ran `just rekey`
- [ ] Added `age.secrets.*` entry to Nix config
- [ ] Ran `agenix-helper lock` when done
