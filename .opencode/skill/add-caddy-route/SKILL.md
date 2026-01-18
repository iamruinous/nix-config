---
name: add-caddy-route
description: Add a reverse proxy route to an encrypted Caddyfile
compatibility: Requires agenix, agenix-helper
metadata:
  author: ruinous.ai
  version: "1.0"
  domain: networking
---

# Add Caddy Route

Add a reverse proxy route to an encrypted Caddyfile.

**Arguments:** `$ARGUMENTS` should contain:
- Hostname (e.g., `pilaster`)
- Domain (e.g., `myservice.meskill.farm`)
- Backend (e.g., `myservice:8080`)

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
