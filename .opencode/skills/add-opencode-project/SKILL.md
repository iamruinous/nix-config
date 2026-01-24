---
name: add-opencode-project
description: Add a new project to opencode-projects with DNS, Caddy, Gatus, and deployment
compatibility: Requires cfcli, nix, ssh access to hosts
metadata:
  author: ruinous.ai
  version: "1.1"
  domain: opencode
parameters:
  hostname:
    type: select
    description: Target host for the OpenCode project
    required: true
    options:
      - label: "chassis (Recommended)"
        description: "Primary AI development hub, ports 9500-9599"
      - label: "obelisk"
        description: "GPU compute server, ports 9600-9699"
      - label: "zenith"
        description: "AI container server, ports 9700-9799"
    default: chassis
  project_dir:
    type: string
    description: Full path to the project directory on the target host
    required: true
    placeholder: "~/Projects/farmforge/iamruinous/my-project"
  domain:
    type: string
    description: Domain for the web interface (must end with .oc.ruinous.ai)
    required: true
    placeholder: "my-project.oc.ruinous.ai"
    pattern: "*.oc.ruinous.ai"
---

# Add OpenCode Project

Add a new project to opencode-projects with full deployment: DNS, Caddy reverse proxy, Gatus monitoring, and host deployment.

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "Which host should run this OpenCode project?",
      header: "Host",
      options: [
        { label: "chassis (Recommended)", description: "Primary AI development hub" },
        { label: "obelisk", description: "GPU compute server" },
        { label: "zenith", description: "AI container server" }
      ]
    },
    {
      question: "What is the full path to the project directory?",
      header: "Project Dir",
      options: [
        { label: "Enter path...", description: "e.g., ~/Projects/farmforge/iamruinous/my-project" }
      ]
    },
    {
      question: "What domain should be used for the web interface?",
      header: "Domain",
      options: [
        { label: "Enter domain...", description: "e.g., my-project.oc.ruinous.ai" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<hostname> <project_dir> <domain>`
- Example: `chassis ~/Projects/farmforge/iamruinous/budgey-extractor budgey-extractor.oc.ruinous.ai`

## Prerequisites

- SSH access to target host and monolith
- cfcli configured with Cloudflare API token
- Project directory exists on target host

## Steps

### 1. Determine next available port

Read the existing projects in the host's home-configuration.nix to find the next available port:

```bash
cat hosts/<hostname>/users/jmeskill/home-configuration.nix | grep "port = "
```

Ports typically start at 9500 and increment. Choose the next available port.

### 2. Derive project name from domain

Extract the project name from the domain (the part before `.oc.ruinous.ai`):
- Domain: `budgey-extractor.oc.ruinous.ai`
- Project name: `budgey-extractor`

For the Nix attribute name, use a simplified version:
- `budgey-extractor` -> `budgey` (or keep full name if unique)

### 3. Add project to home-configuration.nix

Edit `hosts/<hostname>/users/jmeskill/home-configuration.nix`:

Add a new project entry inside `ruinous.ai-cli.opencode-projects.projects`:

```nix
# <project-name> - web service with Caddy
<project-name> = {
  workdir = "<full-project-path>";
  port = <next-port>;
  caddy.fqdn = "<domain>";
};
```

**Example:**
```nix
# budgey-extractor - web service with Caddy
budgey = {
  workdir = "/home/jmeskill/Projects/farmforge/iamruinous/budgey-extractor";
  port = 9508;
  caddy.fqdn = "budgey-extractor.oc.ruinous.ai";
};
```

**Note:** Expand `~` to `/home/jmeskill` in the path.

### 4. Add DNS record

Add CNAME pointing to the host:

```bash
cfcli --domain ruinous.ai --type CNAME add <subdomain-path> <hostname>.meskill.farm
```

For `budgey-extractor.oc.ruinous.ai` on `chassis`:
```bash
cfcli --domain ruinous.ai --type CNAME add budgey-extractor.oc chassis.meskill.farm
```

### 5. Add Gatus monitoring

Edit `hosts/monolith/files/gatus/config.yaml`:

Add a new endpoint under the `# CHASSIS SERVICES (OpenCode)` section (or appropriate host section):

```yaml
  - name: "OpenCode - <project-name> (<hostname>)"
    group: "Development"
    url: "https://<domain>"
    interval: 5m
    conditions:
      - "[STATUS] == 200"
    alerts:
      - type: discord
      - type: email
```

**Example:**
```yaml
  - name: "OpenCode - budgey (chassis)"
    group: "Development"
    url: "https://budgey-extractor.oc.ruinous.ai"
    interval: 5m
    conditions:
      - "[STATUS] == 200"
    alerts:
      - type: discord
      - type: email
```

### 6. Verify builds

Dry-build both hosts to verify configuration:

```bash
just remote-dry-build <hostname>
just remote-dry-build monolith
```

### 7. Deploy to hosts

Deploy to both hosts:

```bash
# Deploy to target host (Caddy routes auto-generated from opencode-projects)
just remote-rebuild <hostname>

# Deploy to monolith (Gatus monitoring)
just remote-rebuild monolith
```

## File Locations Reference

| File | Purpose |
|------|---------|
| `hosts/<hostname>/users/jmeskill/home-configuration.nix` | Project definition |
| `hosts/<hostname>/caddy.nix` | Caddy config (auto-generated from projects) |
| `hosts/monolith/files/gatus/config.yaml` | Uptime monitoring |

## Port Allocation

| Host | Port Range | Notes |
|------|------------|-------|
| chassis | 9500-9599 | Primary OpenCode host |
| obelisk | 9600-9699 | If needed |
| zenith | 9700-9799 | If needed |

## Domain Patterns

| Pattern | Use Case |
|---------|----------|
| `<project>.oc.ruinous.ai` | OpenCode web services |
| `<project>.agent.ruinous.ai` | Agent documentation sites |

## Example: Full Workflow

```bash
# Arguments: chassis ~/Projects/farmforge/iamruinous/budgey-extractor budgey-extractor.oc.ruinous.ai

# 1. Check existing ports
cat hosts/chassis/users/jmeskill/home-configuration.nix | grep "port = "
# Output shows 9500-9507 in use, next is 9508

# 2. Add project to home-configuration.nix
# (edit the file to add new project entry)

# 3. Add DNS record
cfcli --domain ruinous.ai --type CNAME add budgey-extractor.oc chassis.meskill.farm

# 4. Add Gatus monitoring
# (edit hosts/monolith/files/gatus/config.yaml)

# 5. Verify builds
just remote-dry-build chassis
just remote-dry-build monolith

# 6. Deploy
just remote-rebuild chassis
just remote-rebuild monolith
```

## Troubleshooting

### Service not starting
```bash
# Check systemd service status
ssh <hostname> "systemctl --user status opencode-<project>"

# View logs
ssh <hostname> "journalctl --user -fu opencode-<project>.service"
```

### DNS not resolving
```bash
# Check Cloudflare records
cfcli --domain ruinous.ai ls | grep <project>

# Test DNS resolution
dig <domain>
```

### Caddy not proxying
```bash
# Check Caddy logs
ssh <hostname> "journalctl -fu caddy"

# Verify Caddy config
ssh <hostname> "caddy validate --config /etc/caddy/Caddyfile"
```

## Post-Deployment Checklist

- [ ] Project added to home-configuration.nix with correct path and port
- [ ] DNS CNAME record created in Cloudflare
- [ ] Gatus monitoring endpoint added
- [ ] Dry-build passes for both hosts
- [ ] Deployed to target host
- [ ] Deployed to monolith (for Gatus)
- [ ] Web UI accessible at https://<domain>
- [ ] Gatus shows endpoint as healthy
