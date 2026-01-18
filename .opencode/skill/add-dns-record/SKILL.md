---
name: add-dns-record
description: Add or update a DNS record in Cloudflare using cfcli
compatibility: Requires cfcli (Cloudflare CLI)
metadata:
  author: ruinous.ai
  version: "1.0"
  domain: dns
---

# Add DNS Record

Add or update a DNS record in Cloudflare for the meskill.farm domain.

**Arguments:** `$ARGUMENTS` should contain:
- Record name (e.g., `myservice`)
- Target (e.g., `pilaster.meskill.farm`)
- Optionally: record type (CNAME, A, TXT)

## Commands

### List existing records
```bash
cfcli --domain meskill.farm ls
```

### Add CNAME record
```bash
cfcli --domain meskill.farm --type CNAME add <name> <target>
```

### Add with Cloudflare proxy (orange cloud)
```bash
cfcli --domain meskill.farm --type CNAME --activate add <name> <target>
```

### Update existing record
```bash
cfcli --domain meskill.farm --type CNAME edit <name> <target>
```

### Delete record
```bash
cfcli --domain meskill.farm --type CNAME rm <name>
```

## DNS Record Types

| Type | Use Case | Example |
|------|----------|---------|
| CNAME | Service aliases | `ai.meskill.farm` → `obelisk.meskill.farm` |
| A | Direct IP mapping | `host.meskill.farm` → `10.55.20.21` |
| TXT | Verification, SPF | Mail configuration |

## Naming Conventions

| Environment | Pattern | Host |
|-------------|---------|------|
| Production | `<service>.meskill.farm` | Various |
| Testing | `<service>.x.meskill.farm` | zenith |
| Internal (tunnel) | `<service>-int.meskill.farm` | Various |

## Container Hosts

| Host | DNS Entry |
|------|-----------|
| zenith | zenith.meskill.farm |
| obelisk | obelisk.meskill.farm |
| monolith | monolith.meskill.farm |
| pilaster | pilaster.meskill.farm |

## Example

```bash
# Add new service pointing to pilaster
/add-dns-record myservice pilaster.meskill.farm

# Add testing subdomain
/add-dns-record myservice.x zenith.meskill.farm

# Add with Cloudflare proxy
cfcli --domain meskill.farm --type CNAME --activate add myservice pilaster.meskill.farm
```

## Verification

```bash
# Check DNS propagation
dig myservice.meskill.farm

# Flush local DNS cache
sudo systemd-resolve --flush-caches
```
