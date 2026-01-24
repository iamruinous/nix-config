---
name: add-dns-record
description: Add or update a DNS record in Cloudflare using cfcli
compatibility: Requires cfcli (Cloudflare CLI)
metadata:
  author: ruinous.ai
  version: "1.1"
  domain: dns
parameters:
  record_name:
    type: string
    description: DNS record name (subdomain)
    required: true
    placeholder: "myservice"
  target:
    type: select
    description: Target host or address
    required: true
    options:
      - label: "pilaster.meskill.farm"
        description: "Main web services host"
      - label: "monolith.meskill.farm"
        description: "Infrastructure services host"
      - label: "zenith.meskill.farm"
        description: "AI/GPU workloads host"
      - label: "obelisk.meskill.farm"
        description: "GPU compute host"
      - label: "chassis.meskill.farm"
        description: "AI development workstation"
      - label: "Enter custom target..."
        description: "Specify a custom target"
  record_type:
    type: select
    description: DNS record type
    required: false
    default: CNAME
    options:
      - label: "CNAME (Recommended)"
        description: "Alias to another hostname"
      - label: "A"
        description: "Direct IP address"
      - label: "TXT"
        description: "Text record (verification, SPF)"
---

# Add DNS Record

Add or update a DNS record in Cloudflare for the meskill.farm domain.

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "What is the DNS record name (subdomain)?",
      header: "Record Name",
      options: [
        { label: "Enter name...", description: "e.g., myservice, myservice.x (for testing)" }
      ]
    },
    {
      question: "What should this record point to?",
      header: "Target",
      options: [
        { label: "pilaster.meskill.farm", description: "Main web services host" },
        { label: "monolith.meskill.farm", description: "Infrastructure services" },
        { label: "zenith.meskill.farm", description: "AI/GPU workloads" },
        { label: "chassis.meskill.farm", description: "AI development workstation" },
        { label: "Enter custom target...", description: "Specify IP or hostname" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<record_name> <target> [record_type]`
- Example: `myservice pilaster.meskill.farm`
- Example with type: `myservice pilaster.meskill.farm CNAME`

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
