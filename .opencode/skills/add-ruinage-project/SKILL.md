---
name: add-ruinage-project
description: Add a new project to ruinage with DNS, Caddy, Gatus, and deployment
compatibility: Requires cfcli, nix, ssh access to hosts
metadata:
  author: ruinous.ai
  version: "2.0"
  domain: ruinage
parameters:
  forge_url:
    type: string
    description: Full forge URL to the repository
    required: true
    placeholder: "forge.meskill.farm/iamruinous/my-project"
  hostname:
    type: select
    description: Target host for the ruinage project
    required: false
    options:
      - label: "chassis (Recommended)"
        description: "Primary AI development hub"
      - label: "obelisk"
        description: "GPU compute server"
      - label: "zenith"
        description: "AI container server"
    default: chassis
---

# Add Ruinage Project

Add a new project to ruinage with full deployment: DNS, Caddy reverse proxy, Gatus monitoring, and host deployment.

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "What is the forge URL for the repository?",
      header: "Forge URL",
      options: []  // custom input
    },
    {
      question: "Which host should run this project?",
      header: "Host",
      options: [
        { label: "chassis (Recommended)", description: "Primary AI development hub" },
        { label: "obelisk", description: "GPU compute server" },
        { label: "zenith", description: "AI container server" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<forge_url> [hostname]`
- Example: `forge.meskill.farm/iamruinous/budgey-assistant-dashboard chassis`
- Example: `forge.meskill.farm/iamruinous/budgey-assistant-dashboard` (defaults to chassis)

## Prerequisites

- SSH access to target host and monolith
- cfcli configured with Cloudflare API token

## Parsing Forge URL

From `forge.meskill.farm/iamruinous/budgey-assistant-dashboard`:
- **forge**: `forge.meskill.farm`
- **owner**: `iamruinous`
- **repo**: `budgey-assistant-dashboard`
- **project name** (Nix attr): `budgey-assistant-dashboard`
- **workdir**: `~/Projects/ruinage/budgey-assistant-dashboard`
- **domain**: `budgey-assistant-dashboard.oc.ruinous.ai`

## Steps

### 1. Add project to home-configuration.nix

Edit `hosts/<hostname>/users/jmeskill/home-configuration.nix`:

Add a new project entry inside `ruinous.ruinage.projects`:

```nix
# <repo> - web service with Caddy
<project-name> = {
  # Only specify if different from project name
  # repo = "<repo-name>";
  # Only specify if different from default (forge.meskill.farm)
  # forge = "<forge>";
  # Only specify if different from default (iamruinous)
  # owner = "<owner>";
  assistants.opencode = {
    enable = true;
    web.enable = true;
    budgey.enable = true;
  };
  assistants.kimaki.enable = true;
  direnv.enable = true;
  environmentFiles = [
    config.age.secrets.chassis_opencode_common_env.path
  ];
};
```

**Key points:**
- Project name defaults to repo name
- `forge` defaults to `forge.meskill.farm`
- `owner` defaults to `iamruinous`
- `workdir` auto-computes to `~/Projects/ruinage/<repo>`
- `web.fqdn` auto-computes to `<project-name>.oc.ruinous.ai`
- Port is auto-assigned based on alphabetical order (no manual port needed!)

### 2. Add DNS record

Add CNAME pointing to the host:

```bash
cfcli --domain ruinous.ai --type CNAME add <project-name>.oc <hostname>.meskill.farm
```

Example for `budgey-assistant-dashboard` on `chassis`:
```bash
cfcli --domain ruinous.ai --type CNAME add budgey-assistant-dashboard.oc chassis.meskill.farm
```

### 3. Add Gatus monitoring

Edit `hosts/monolith/files/gatus/config.yaml`:

Add a new endpoint under the `# CHASSIS SERVICES (OpenCode)` section (or appropriate host section):

```yaml
  - name: "OpenCode - <project-name> (<hostname>)"
    group: "Development"
    url: "https://<project-name>.oc.ruinous.ai"
    interval: 5m
    conditions:
      - "[STATUS] == 200"
    alerts:
      - type: discord
      - type: email
```

### 4. Verify builds

Dry-build both hosts to verify configuration:

```bash
just remote-dry-build <hostname>
just remote-dry-build monolith
```

### 5. Clone the repository (if not exists)

```bash
mkdir -p ~/Projects/ruinage
cd ~/Projects/ruinage
git clone git@<forge>:<owner>/<repo>.git
```

### 6. Deploy to hosts

Deploy to both hosts:

```bash
# Deploy to target host (Caddy routes auto-generated from projects)
just remote-rebuild <hostname>

# Deploy to monolith (Gatus monitoring)
just remote-rebuild monolith
```

## New Ruinage Project Structure

The new ruinage module automatically handles:

| Feature | Auto-Generated |
|---------|----------------|
| workdir | `~/Projects/ruinage/<repo>` |
| web.fqdn | `<project-name>.oc.ruinous.ai` |
| web.port | Auto-assigned (alphabetical order from 9500) |
| Caddy routes | From `assistants.opencode.web.enable` |
| tmuxp session | From project config |
| direnv | From `direnv.enable` |

## File Locations Reference

| File | Purpose |
|------|---------|
| `hosts/<hostname>/users/jmeskill/home-configuration.nix` | Project definition |
| `hosts/<hostname>/caddy.nix` | Caddy config (auto-generated from projects) |
| `hosts/monolith/files/gatus/config.yaml` | Uptime monitoring |

## Domain Patterns

| Pattern | Use Case |
|---------|----------|
| `<project>.oc.ruinous.ai` | OpenCode web services |
| `<project>.agent.ruinous.ai` | Agent documentation sites |

## Example: Full Workflow

```bash
# Arguments: forge.meskill.farm/iamruinous/budgey-assistant-dashboard

# 1. Parse URL
# forge = forge.meskill.farm
# owner = iamruinous
# repo = budgey-assistant-dashboard
# project = budgey-assistant-dashboard
# domain = budgey-assistant-dashboard.oc.ruinous.ai

# 2. Add project to home-configuration.nix
# (edit the file to add new project entry)

# 3. Add DNS record
cfcli --domain ruinous.ai --type CNAME add budgey-assistant-dashboard.oc chassis.meskill.farm

# 4. Add Gatus monitoring
# (edit hosts/monolith/files/gatus/config.yaml)

# 5. Verify builds
just remote-dry-build chassis
just remote-dry-build monolith

# 6. Clone if needed
cd ~/Projects/ruinage && git clone git@forge.meskill.farm:iamruinous/budgey-assistant-dashboard.git

# 7. Deploy
just remote-rebuild chassis
just remote-rebuild monolith
```

## Troubleshooting

### Service not starting
```bash
# Check systemd service status
systemctl --user status opencode-<project>

# View logs
journalctl --user -fu opencode-<project>.service
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
journalctl -fu caddy

# Verify Caddy config
caddy validate --config /etc/caddy/Caddyfile
```

## Post-Deployment Checklist

- [ ] Project added to home-configuration.nix
- [ ] DNS CNAME record created in Cloudflare
- [ ] Gatus monitoring endpoint added
- [ ] Dry-build passes for both hosts
- [ ] Repository cloned to ~/Projects/ruinage/
- [ ] Deployed to target host
- [ ] Deployed to monolith (for Gatus)
- [ ] Web UI accessible at https://<project>.oc.ruinous.ai
- [ ] Gatus shows endpoint as healthy
