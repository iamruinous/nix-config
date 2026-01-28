---
name: nix-deploy
description: Deploy NixOS/Darwin configuration to local or remote host using justfile commands
compatibility: Requires nix, just
metadata:
  author: ruinous.ai
  version: "2.0"
  domain: deployment
parameters:
  hostname:
    type: select
    description: Target host to deploy to (defaults to current host if omitted)
    required: false
    options:
      - label: "chassis"
        description: "AI development workstation (NixOS)"
      - label: "framework"
        description: "NixOS laptop"
      - label: "monolith"
        description: "Infrastructure hub"
      - label: "pilaster"
        description: "Container server"
      - label: "zenith"
        description: "AI containers"
      - label: "obelisk"
        description: "GPU compute"
      - label: "jbookpro"
        description: "MacBook Pro (Darwin)"
      - label: "jmacmini"
        description: "Mac Mini (Darwin)"
      - label: "Enter other..."
        description: "Specify a different host"
  dry_run:
    type: select
    description: Whether to perform a dry-build first
    required: false
    default: "Yes"
    options:
      - label: "Yes (Recommended)"
        description: "Verify build before deploying"
      - label: "No"
        description: "Deploy directly"
---

# Nix Deploy

Deploy NixOS or Darwin configuration to a local or remote host.

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "Which host do you want to deploy to?",
      header: "Host",
      options: [
        { label: "Current host (default)", description: "Deploy to this machine" },
        { label: "chassis", description: "AI development workstation (NixOS)" },
        { label: "framework", description: "NixOS laptop" },
        { label: "monolith", description: "Infrastructure hub" },
        { label: "pilaster", description: "Container server" },
        { label: "zenith", description: "AI containers" },
        { label: "obelisk", description: "GPU compute" },
        { label: "jbookpro", description: "MacBook Pro (Darwin)" },
        { label: "jmacmini", description: "Mac Mini (Darwin)" }
      ]
    },
    {
      question: "Perform dry-build verification first?",
      header: "Dry Run",
      options: [
        { label: "Yes (Recommended)", description: "Verify build before deploying" },
        { label: "No", description: "Deploy directly" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `[hostname] [--no-dry-run]`
- Example: (empty) - deploy to current host with dry-build
- Example: `pilaster` - deploy to pilaster with dry-build
- Example: `monolith --no-dry-run` - deploy directly without verification

## Steps

### 1. Dry-build verification (recommended)

**Smart check (auto-detects Darwin vs NixOS, local vs remote):**
```bash
just check [hostname]
```

If hostname is omitted, uses current host.

### 2. Deploy

**Smart deploy (auto-detects local vs remote, Darwin vs Linux):**
```bash
just deploy [hostname]
```

If hostname is omitted, uses current host.

### 3. Verify deployment

After deployment completes:

```bash
# For remote hosts, SSH and check
ssh <hostname>.meskill.farm "systemctl status" | head -20

# For services, verify they're running
ssh <hostname>.meskill.farm "systemctl status docker-caddy"
```

## Host Reference

### Container Hosts

| Host | Role | Platform |
|------|------|----------|
| **monolith** | Infrastructure hub, Cloudflared tunnels | NixOS |
| **pilaster** | Container server, databases | NixOS |
| **zenith** | AI containers, testing | NixOS |
| **obelisk** | GPU compute, MicroVMs | NixOS |

### Workstations

| Host | Role | Platform |
|------|------|----------|
| **chassis** | AI development workstation | NixOS |
| **framework** | NixOS laptop | NixOS |
| **jbookpro** | MacBook Pro | Darwin |
| **jmacmini** | Mac Mini | Darwin |

## Common Deployment Scenarios

### After changing container configuration

```bash
# 1. Verify the build
just check pilaster

# 2. Deploy
just deploy pilaster

# 3. Verify container is running
ssh pilaster.meskill.farm "docker ps | grep <container-name>"
```

### After changing Caddy routes

```bash
# 1. Deploy host with Caddy changes
just deploy <hostname>

# 2. Caddy auto-reloads when Caddyfile changes (via systemd trigger)
```

### After changing secrets

```bash
# 1. Rekey secrets first
just rekey

# 2. Deploy to host
just deploy <hostname>
```

### Full container deployment workflow

Use `/deploy-container` skill for the complete workflow, which includes:
1. Create encrypted env
2. Add DNS record
3. Configure Caddy routes
4. Deploy with this skill

## Pre-Deployment Checklist

- [ ] Changes committed (or stashed) - deployment reads from working directory
- [ ] No unencrypted secrets in configuration
- [ ] Container images pinned (no `:latest`)
- [ ] `just check [host]` passes

## Troubleshooting

### Build fails with "attribute not found"

```bash
# Check the host configuration exists
ls hosts/<hostname>/configuration.nix
ls hosts/<hostname>/darwin-configuration.nix
```

### Remote deploy times out

```bash
# Verify SSH connectivity
ssh <hostname>.meskill.farm "hostname"

# Check if rebuild is stuck
ssh <hostname>.meskill.farm "journalctl -f"
```

### Darwin deploy permission denied

```bash
# Darwin rebuilds need sudo
sudo --preserve-env=SSH_AUTH_SOCK darwin-rebuild switch --flake .#<hostname>
```

## Example

```bash
# Deploy to current host with verification
/nix-deploy

# Deploy to pilaster with verification
/nix-deploy pilaster

# Deploy to chassis without dry-run
/nix-deploy chassis --no-dry-run

# Deploy to monolith after container changes
/nix-deploy monolith
```
