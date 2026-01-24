---
name: setup-cloudflare-tunnel
description: Create and configure a Cloudflare Tunnel for external service access
compatibility: Requires cloudflared, agenix, cfcli
metadata:
  author: ruinous.ai
  version: "1.1"
  domain: networking
parameters:
  tunnel_name:
    type: string
    description: Name for the Cloudflare tunnel
    required: true
    placeholder: "myservice"
  hostname:
    type: select
    description: Target host where cloudflared will run
    required: true
    options:
      - label: "pilaster (Recommended)"
        description: "Main web services host"
      - label: "monolith"
        description: "Infrastructure services host"
      - label: "zenith"
        description: "AI/GPU workloads host"
  domain:
    type: string
    description: Public domain for the service
    required: true
    placeholder: "myservice.meskill.farm"
---

# Setup Cloudflare Tunnel

Create and configure a Cloudflare Tunnel to expose internal services to the internet without opening firewall ports.

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "What should the tunnel be named?",
      header: "Tunnel Name",
      options: [
        { label: "Enter name...", description: "e.g., myservice (used for config references)" }
      ]
    },
    {
      question: "Which host will run cloudflared?",
      header: "Host",
      options: [
        { label: "pilaster (Recommended)", description: "Main web services host" },
        { label: "monolith", description: "Infrastructure services" },
        { label: "zenith", description: "AI/GPU workloads" }
      ]
    },
    {
      question: "What public domain should expose the service?",
      header: "Domain",
      options: [
        { label: "Enter domain...", description: "e.g., myservice.meskill.farm" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<tunnel_name> <hostname> <domain>`
- Example: `myservice pilaster myservice.meskill.farm`

## Architecture

```
Internet → Cloudflare Edge → Tunnel (cloudflared) → Caddy → Service
```

## Steps

### 1. Authenticate with Cloudflare

```bash
cloudflared tunnel login
```
Opens browser for authentication, creates `~/.cloudflared/cert.pem`.

### 2. Create the Tunnel

```bash
cloudflared tunnel create <tunnel-name>
```

Outputs:
- **Tunnel ID**: UUID like `9b4d96ca-4911-46d3-979e-38f3d6dae733`
- **Credentials**: `~/.cloudflared/<tunnel-id>.json`

### 3. Encrypt Credentials

```bash
# Unlock agenix
agenix-helper unlock

# Create directory
mkdir -p hosts/<hostname>/files/cloudflared

# Encrypt cert.pem (one per host, reusable)
agenix edit -i ~/.cloudflared/cert.pem \
            hosts/<hostname>/files/cloudflared/cert.pem.age

# Encrypt tunnel credentials
agenix edit -i ~/.cloudflared/<tunnel-id>.json \
            hosts/<hostname>/files/cloudflared/<tunnel-name>.json.age

# Clean up unencrypted files
rm ~/.cloudflared/cert.pem ~/.cloudflared/<tunnel-id>.json

# Rekey
agenix rekey -a
```

### 4. Configure NixOS

Create or update `hosts/<hostname>/cloudflared.nix`:

```nix
{config, ...}: {
  services.cloudflared = {
    enable = true;
    tunnels = {
      "<tunnel-id>" = {
        credentialsFile = "${config.age.secrets.<hostname>_cloudflared_<tunnel>.path}";
        ingress = {
          "<service>.meskill.farm" = "https://<service>-int.meskill.farm";
        };
        default = "http_status:404";
      };
    };
  };

  # cert.pem for tunnel management
  age.secrets.<hostname>_cloudflared_cert_pem = {
    rekeyFile = ./files/cloudflared/cert.pem.age;
    path = "/etc/cloudflared/cert.pem";
    mode = "644";
  };

  # Tunnel credentials
  age.secrets.<hostname>_cloudflared_<tunnel> = {
    rekeyFile = ./files/cloudflared/<tunnel-name>.json.age;
    mode = "644";
  };
}
```

### 5. Update Caddyfile

Both internal and external domains:

```
<service>-int.meskill.farm <service>.meskill.farm {
  reverse_proxy <container>:<port>
}
```

### 6. Configure DNS

```bash
# Internal domain (for Caddy)
cfcli --domain meskill.farm --type CNAME add <service>-int <hostname>.meskill.farm

# External domain (proxied through Cloudflare tunnel)
cfcli --domain meskill.farm --type CNAME --activate add <service> <tunnel-id>.cfargotunnel.com
```

### 7. Deploy

```bash
just remote-rebuild <hostname>
```

## Existing Tunnels

| Host | Services |
|------|----------|
| monolith | n8n webhook |
| pilaster | monica, music-assistant, twenty, ma-alexa |

## Troubleshooting

### Tunnel not connecting
```bash
systemctl status cloudflared-tunnel-<tunnel-id>
journalctl -u cloudflared-tunnel-<tunnel-id> -f
```

### Verify credentials exist
```bash
ls -la /run/agenix/ | grep cloudflared
```

## Example

```bash
/setup-cloudflare-tunnel myservice pilaster myservice.meskill.farm
```
