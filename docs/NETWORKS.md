# Network Architecture

> VLANs, DNS domains, and network conventions for the ruinous.ai infrastructure.

---

## VLANs

| VLAN | Name | CIDR | Gateway | Purpose |
|------|------|------|---------|---------|
| 1 | Management | 10.55.10.0/24 | 10.55.10.1 | Network management, HA pair |
| 2 | Services | 10.55.20.0/24 | 10.55.20.1 | Container hosts, servers |
| 3 | Home | 10.55.30.0/24 | 10.55.30.1 | Home devices, IoT, workstations |

### VLAN 1 - Management (10.55.10.0/24)

| Host | IP | Role |
|------|-----|------|
| void | 10.55.10.36 | HA master (VRRP) |
| gap | 10.55.10.37 | HA backup (VRRP) |
| VIP | 10.55.10.34 | Virtual IP (Keepalived) |
| DNS | 10.55.10.35 | DNS server |

### VLAN 2 - Services (10.55.20.0/24)

| Host | IP | Role |
|------|-----|------|
| zenith | 10.55.20.21 | AI containers (AMD) |
| obelisk | 10.55.20.22 | GPU compute (NVIDIA) |
| armistice | 10.55.20.23 | ARM workstation |
| monolith | 10.55.20.24 | Infrastructure hub |
| pilaster | 10.55.20.25 | Container server |
| messy-tty | 10.55.20.80 | MicroVM |
| ruinous-tty | 10.55.20.81 | MicroVM |
| builder-tty | 10.55.20.82 | Builder MicroVM |

---

## DNS Domains

### Primary Domains

| Domain | Purpose | Provider |
|--------|---------|----------|
| `meskill.farm` | Production services (internal) | Cloudflare |
| `ruinous.ai` | Agent ecosystem | Cloudflare |
| `ruinous.social` | Public-facing services (blog, social, bookmarks) | Cloudflare |
| `meskill.network` | Internal/legacy | Cloudflare |

### Subdomain Patterns

| Pattern | Purpose | Example |
|---------|---------|---------|
| `<service>.meskill.farm` | Production services | `n8n.meskill.farm` |
| `<service>.x.meskill.farm` | Testing/staging (zenith) | `ai.x.meskill.farm` |
| `<service>-int.meskill.farm` | Internal (pre-tunnel) | `monica-int.meskill.farm` |
| `<host>.meskill.farm` | Host direct access | `monolith.meskill.farm` |

### ruinous.ai Subdomains

| Pattern | Purpose | Host | Example |
|---------|---------|------|---------|
| `<persona>.agent.ruinous.ai` | Agent documentation sites | chassis | `messy.agent.ruinous.ai` |
| `agents.ruinous.ai` | Agent ecosystem hub | chassis | - |
| `<project>.oc.ruinous.ai` | OpenCode web services | chassis | `nix.oc.ruinous.ai` |
| `<host>.<type>.ruinous.ai` | Host-specific services | varies | `zenith.ui.ruinous.ai` |

### ruinous.social Subdomains

| Pattern | Purpose | Example |
|---------|---------|---------|
| `ruinous.social` | Primary blog/landing | - |
| `<service>.ruinous.social` | Public services | `links.ruinous.social` |
| `@user@ruinous.social` | Fediverse handles | `@jade@ruinous.social` |

**Use ruinous.social for:**
- Blog and public content
- Social media presence (Mastodon, etc.)
- Bookmark managers (Linkding, etc.)
- Public-facing tools meant for external users

### Internal Network Domains

| Pattern | Purpose | Example |
|---------|---------|---------|
| `<service>.svc.farmhouse.meskill.network` | Internal services (LAN only) | `ai.svc.farmhouse.meskill.network` |
| `<host>.manage.farmhouse.meskill.network` | Management interfaces | `terranas.manage.farmhouse.meskill.network` |
| `<host>.tty.meskill.farm` | MicroVM hosts | `messy.tty.meskill.farm` |

---

## Container Networks

Docker networks used on container hosts (monolith, pilaster, zenith, obelisk):

| Network | Purpose | Flags | Access Pattern |
|---------|---------|-------|----------------|
| `servicenet` | Application containers | - | Caddy → container:port |
| `datanet` | Databases, caches | `--internal` | App → db:port (no external) |
| `proxynet` | Host port binding | - | host:port → container:port |
| `forgejo-actions` | CI/CD runners | - | Runner → DinD |

### Network Selection Guide

```
Internet
    │
    ▼
┌─────────────────────────────┐
│   Caddy (proxynet + servicenet)
│   Ports: 80, 443
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│         servicenet          │
│   Apps, APIs, Web UIs       │
│   (accessible via Caddy)    │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│   datanet (--internal)      │
│   PostgreSQL, Redis, etc.   │
│   (no external access)      │
└─────────────────────────────┘
```

**Decision tree:**
- Need Caddy access? → `servicenet`
- Database/cache? → `datanet` (internal only)
- Need host ports? → `proxynet`
- Both app and DB access? → `servicenet` + `datanet`

---

## Cloudflare Tunnels

External access without opening firewall ports:

| Host | Tunnel | Services |
|------|--------|----------|
| monolith | n8n-webhook | `n8h.meskill.farm` → n8n webhooks |
| pilaster | music-assistant | `ma.meskill.farm` → Music Assistant |
| pilaster | ma-alexa | `ma-alexa.meskill.farm` → MA Alexa skill |
| pilaster | monica | `monica.meskill.farm` → Monica CRM |
| pilaster | twenty | `twenty.meskill.farm` → Twenty CRM |
| zenith | timeline | `timeline.meskill.farm` → Dawarich |

### Tunnel DNS Pattern

For tunneled services, two DNS records are needed:

```
# Internal (for Caddy to resolve)
<service>-int.meskill.farm → CNAME → <host>.meskill.farm

# External (for tunnel routing)  
<service>.meskill.farm → CNAME (proxied) → <tunnel-id>.cfargotunnel.com
```

---

## Tailscale VPN

**MagicDNS:** `greyhound-triceratops.ts.net`

Hosts are accessible via `<hostname>.greyhound-triceratops.ts.net` when connected to Tailscale.

### Subnet Routes

Hosts advertising subnet routes for remote access:

| Host | Route | Purpose |
|------|-------|---------|
| monolith | 10.55.0.0/16 | Primary on-prem access |
| obelisk | 10.55.0.0/16 | Backup on-prem access |
| pilaster | 10.55.0.0/16 | Backup on-prem access |
| zenith | 10.55.0.0/16 | Backup on-prem access |
| tty-ruinous-social | 10.55.0.0/16 | Cloud → on-prem access |

### MagicDNS Examples

```
monolith.greyhound-triceratops.ts.net
pilaster.greyhound-triceratops.ts.net
chassis.greyhound-triceratops.ts.net
```

---

## Service Categories by Host

### monolith (Infrastructure Hub)

| Category | Services |
|----------|----------|
| Media | radarr, sonarr, bazarr, prowlarr, plex, jellyfin |
| Automation | n8n, changedetection, paperless |
| Monitoring | grafana, prometheus, loki, gatus |
| Dev | forge (Forgejo), adminer |
| Home | frigate, zigbee2mqtt, mqtt |

### pilaster (Container Server)

| Category | Services |
|----------|----------|
| Productivity | twenty, monica, homebox |
| Documentation | wikijs, docs |
| Security | authentik (auth) |
| Tools | archivebox, qdrant, mcp-gateway |

### zenith (AI/Testing)

| Category | Services |
|----------|----------|
| AI | ollama, open-webui, mcp-gateway |
| Testing | `*.x.meskill.farm` staging services |
| Dev | timeline (Dawarich), nominatim |

### obelisk (GPU Compute)

| Category | Services |
|----------|----------|
| AI | ollama (NVIDIA), open-webui |
| VMs | MicroVMs (messy-tty, ruinous-tty) |

### chassis (Workstation)

| Category | Services |
|----------|----------|
| Agents | `*.agent.ruinous.ai` docs sites |
| OpenCode | `*.oc.ruinous.ai` dev services |

---

## Quick Reference

### Add New Service

1. **Pick host** based on requirements (GPU, resources, category)
2. **Pick domain pattern:**
   - Production: `<service>.meskill.farm`
   - Testing: `<service>.x.meskill.farm`
   - Agent-related: `<service>.ruinous.ai`
3. **Pick networks:**
   - App only: `servicenet`
   - App + DB: `servicenet` + `datanet`
   - External: Add Cloudflare tunnel
4. **Create DNS:**
   ```bash
   cfcli --domain meskill.farm --type CNAME add <service> <host>.meskill.farm
   ```

### Common DNS Commands

```bash
# List all records
cfcli --domain meskill.farm ls

# Add internal service
cfcli --domain meskill.farm --type CNAME add myservice monolith.meskill.farm

# Add tunneled service (external)
cfcli --domain meskill.farm --type CNAME --activate add myservice <tunnel-id>.cfargotunnel.com

# Add internal endpoint for tunnel
cfcli --domain meskill.farm --type CNAME add myservice-int pilaster.meskill.farm
```

---

## Related

- [Hosts](../hosts/README.md) - Host specifications
- [NIXEY SME](https://agents.ruinous.ai/smes/nixey/) - Infrastructure expertise
- [cfnix agent](../.opencode/agents/cfnix.md) - Cloudflare operations
- [containnix agent](../.opencode/agents/containnix.md) - Container deployment
