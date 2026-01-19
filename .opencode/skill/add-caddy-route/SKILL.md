---
name: add-caddy-route
description: Add a reverse proxy route to an encrypted Caddyfile
compatibility: Requires agenix, agenix-helper
metadata:
  author: ruinous.ai
  version: "1.1"
  domain: networking
parameters:
  hostname:
    type: select
    description: Host where Caddy runs
    required: true
    options:
      - label: "pilaster (Recommended)"
        description: "Main web services host"
      - label: "monolith"
        description: "Infrastructure services host"
      - label: "zenith"
        description: "AI/GPU workloads host"
      - label: "obelisk"
        description: "GPU compute host"
  domain:
    type: string
    description: Domain for the route (e.g., myservice.meskill.farm)
    required: true
    placeholder: "myservice.meskill.farm"
  backend:
    type: string
    description: Backend service address (container:port)
    required: true
    placeholder: "myservice:8080"
---

# Add Caddy Route

Add a reverse proxy route to an encrypted Caddyfile.

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "Which host's Caddyfile should be updated?",
      header: "Host",
      options: [
        { label: "pilaster (Recommended)", description: "Main web services host" },
        { label: "monolith", description: "Infrastructure services" },
        { label: "zenith", description: "AI/GPU workloads" },
        { label: "obelisk", description: "GPU compute host" }
      ]
    },
    {
      question: "What domain should this route serve?",
      header: "Domain",
      options: [
        { label: "Enter domain...", description: "e.g., myservice.meskill.farm" }
      ]
    },
    {
      question: "What is the backend service address?",
      header: "Backend",
      options: [
        { label: "Enter backend...", description: "e.g., myservice:8080 (container:port)" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<hostname> <domain> <backend>`
- Example: `pilaster myservice.meskill.farm myservice:8080`

## Steps

### 1. Unlock agenix
```bash
agenix-helper unlock
```

### 2. Export current Caddyfile
```bash
agenix view hosts/<hostname>/files/caddy/Caddyfile.age > /tmp/Caddyfile
```

### 3. Add the new route
Append to `/tmp/Caddyfile`:

```
<domain> {
  reverse_proxy <backend>
}
```

### 4. Re-encrypt
```bash
rm hosts/<hostname>/files/caddy/Caddyfile.age
agenix edit -i /tmp/Caddyfile hosts/<hostname>/files/caddy/Caddyfile.age
rm /tmp/Caddyfile
```

### 5. Rekey and lock
```bash
agenix rekey -a
agenix-helper lock
```

## Caddyfile Patterns

### Basic Reverse Proxy
```
service.meskill.farm {
  reverse_proxy container:8080
}
```

### With Header Modification
```
ollama.meskill.farm {
  reverse_proxy ollama:11434 {
    header_up Host localhost
  }
}
```

### Cloudflare Tunnel (Internal + External)
```
service-int.meskill.farm service.meskill.farm {
  reverse_proxy container:8080
}
```

### Multiple Domains
```
service.meskill.farm www.service.meskill.farm {
  reverse_proxy container:8080
}
```

## Global Config (usually at top)

```
{
  acme_dns cloudflare {env.CF_API_TOKEN}
  email admin@meskill.network
}
```

## Caddy Restart

The Caddy container is configured to restart on Caddyfile changes:

```nix
systemd.services.docker-caddy = {
  restartTriggers = [config.age.secrets.<hostname>_caddy_caddyfile.path];
};
```

## Example

```bash
/add-caddy-route pilaster myservice.meskill.farm myservice:8080
```

## Verification

After deployment:
```bash
# Check Caddy config is valid
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Reload Caddy
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```
