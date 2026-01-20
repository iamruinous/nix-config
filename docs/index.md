# nix-config Documentation

> Declarative infrastructure for 24 hosts — where NixOS, macOS, and Raspberry Pis converge.

**Hidden gem:** The real power isn't in any single host configuration—it's in the module system. Need Steam on a desktop? Import `modules/nixos/desktop/steam`. Want Tailscale everywhere? It's in `modules/nixos/default/tailscale`. This composability means you can spin up a new host in minutes, not hours.

---

## At a Glance

| Aspect | Details |
|--------|---------|
| **SME** | [NIXEY](https://agents.ruinous.ai/smes/nixey/) — Infrastructure |
| **Repository** | [nix-config](https://github.com/iamruinous/nix-config) |
| **Status** | Active (24 hosts managed) |
| **Stack** | NixOS, nix-darwin, Home Manager, Agenix, Blueprint |

---

## What This Project Does

This repository manages the entire ruinous.ai infrastructure declaratively:

| Category | Count | Examples |
|----------|-------|----------|
| **NixOS Servers** | 14 | monolith, pilaster, zenith, obelisk |
| **Raspberry Pi Cluster** | 8 | rpc-5-alpha through rpc-4-hotel |
| **macOS Systems** | 3 | jbookpro, jmacmini, studio |
| **MicroVMs** | 2 | ruinous-tty, messy-tty |

**The insight:** Every host is defined in code. No snowflakes. When obelisk's GPU catches fire, rebuilding it is `just remote-rebuild obelisk`, not a week of archaeology.

---

## Quick Links

| I want to... | Go to |
|--------------|-------|
| Find a host | [hosts/README.md](../hosts/README.md) |
| Understand the networks | [NETWORKS.md](NETWORKS.md) |
| Work with secrets | [secrets/README.md](../secrets/README.md) |
| Add a package | [packages/README.md](../packages/README.md) |
| Deploy a container | [Root AGENTS.md](../AGENTS.md) → `/deploy-container` skill |
| Create a database | [Root AGENTS.md](../AGENTS.md) → `/create-db` skill |

---

## Host Inventory

### Container Hosts (Primary Workloads)

| Host | Hardware | Role | GPU |
|------|----------|------|-----|
| **monolith** | MS-01 (i9-13900H, 96GB) | Infrastructure hub, Cloudflared | - |
| **pilaster** | MS-01 (i9-13900H, 96GB) | Container server, databases | - |
| **zenith** | MS-S1 MAX (Ryzen AI Max+, 128GB) | AI containers, testing | Radeon 8060S |
| **obelisk** | Aurora R16 (i9-14900KF, 64GB) | GPU compute, MicroVMs | RTX 4090 |

### Workstations

| Host | Type | Role |
|------|------|------|
| **chassis** | Desktop | Primary dev, OpenCode services |
| **framework** | Laptop | Mobile dev |
| **jbookpro** | MacBook Pro M4 | macOS dev |
| **jmacmini** | Mac mini M2 Pro | macOS dev |

### Raspberry Pi Cluster

8 nodes: `rpc-5-{alpha,bravo,charlie,delta}` (Pi 5, 8GB) and `rpc-4-{echo,foxtrot,golf,hotel}` (Pi 4, 4GB)

---

## Network Architecture

| Network | Purpose | Example Use |
|---------|---------|-------------|
| `servicenet` | Inter-container + Caddy | App talks to Redis |
| `datanet` | Internal databases | Postgres isolation |
| `proxynet` | Host port binding | External access |

| Domain | Purpose |
|--------|---------|
| `meskill.farm` | Internal production |
| `ruinous.ai` | Agent ecosystem |
| `ruinous.social` | Public-facing |

For complete network documentation, see [NETWORKS.md](NETWORKS.md).

---

## Skills (Automation Workflows)

The nix-config repo has extensive skills for common operations:

| Category | Skills |
|----------|--------|
| **Secrets** | `/encrypt-secret`, `/view-secret`, `/rekey-secrets` |
| **DNS** | `/add-dns-record`, `/setup-cloudflare-tunnel`, `/add-caddy-route` |
| **Containers** | `/deploy-container`, `/create-db-*` |
| **Packaging** | `/create-nix-package`, `/update-package`, `/wrap-shell-script` |
| **Infrastructure** | `/create-pi-host`, `/kde-extract` |

Full skill documentation in [Root AGENTS.md](../AGENTS.md).

---

## Common Commands

```bash
# Deployment
just remote-rebuild <host>     # Deploy to remote host
just remote-dry-build <host>   # Verify build first

# Secrets
agenix-helper unlock           # Before editing secrets
agenix rekey -a                # After changing secrets.nix
agenix-helper lock             # When done

# Validation
just check                     # Dry-build representative hosts
```

---

## Related Projects

- [ruinagents](https://agents.ruinous.ai/) — Agent protocols and personas
- [n8n-agent](../n8n-agent/) — Workflow automation
- [budgey-dashboard](../budgey-dashboard/) — Cost analytics
