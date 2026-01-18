# nix-config

> Declarative NixOS/Darwin infrastructure for 24 hosts.

**LLM Context:** [llms.txt](llms.txt) | **Full Docs:** [agents.ruinous.ai](https://agents.ruinous.ai)

---

## NIXEY - Infrastructure SME

This repository is the domain of **[NIXEY](https://agents.ruinous.ai/smes/nixey/)**, the infrastructure subject matter expert for ruinous.ai.

**NIXEY provides:** Infrastructure context, deployment patterns, architecture decisions  
**Sisyphus executes:** Via oh-my-opencode orchestration and skills

---

## Tiered Context Loading

| Need | Load |
|------|------|
| LLM-friendly overview | [llms.txt](llms.txt) |
| Full NIXEY expertise | [agents.ruinous.ai/smes/nixey](https://agents.ruinous.ai/smes/nixey/) |
| Host details | [hosts/README.md](hosts/README.md) |
| Networks & DNS | [docs/NETWORKS.md](docs/NETWORKS.md) |
| Secrets patterns | [secrets/README.md](secrets/README.md) |
| Package docs | [packages/README.md](packages/README.md) |

---

## Quick Reference

### Container Hosts

| Host | Role | GPU |
|------|------|-----|
| **monolith** | Infrastructure hub, Cloudflared tunnels | - |
| **pilaster** | Container server, databases | - |
| **zenith** | AI containers, testing | Radeon 8060S |
| **obelisk** | GPU compute, MicroVMs | RTX 4090 |

### Networks

| Network | Purpose |
|---------|---------|
| `servicenet` | Inter-container + Caddy access |
| `datanet` | Internal databases (--internal) |
| `proxynet` | Host port binding |

### Commands

```bash
just remote-rebuild <host>     # Deploy to host
just remote-dry-build <host>   # Verify build
just check                     # Dry-build representative hosts
agenix-helper unlock           # Unlock secrets for editing
```

---

## Skills

### Secrets Management

| Skill | Purpose |
|-------|---------|
| `/encrypt-secret` | Create or update an encrypted .age file |
| `/view-secret` | Decrypt and view a secret |
| `/rekey-secrets` | Re-encrypt all secrets after changes |

### DNS & Networking

| Skill | Purpose |
|-------|---------|
| `/add-dns-record` | Add CNAME/A record to Cloudflare |
| `/setup-cloudflare-tunnel` | Create and configure a Cloudflare tunnel |
| `/add-caddy-route` | Add reverse proxy route to Caddyfile |

### Container Deployment

| Skill | Purpose |
|-------|---------|
| `/deploy-container` | Full container deployment workflow |
| `/create-db` | Create PostgreSQL database (asks which host) |
| `/create-db-pilaster` | Create database on pilaster |
| `/create-db-monolith` | Create database on monolith |
| `/create-db-zenith` | Create database on zenith |

### Nix Packaging

| Skill | Purpose |
|-------|---------|
| `/create-nix-package` | Create new Nix package from source |
| `/wrap-shell-script` | Convert shell script to Nix package |
| `/update-package` | Update package version with automatic hash resolution |

### Infrastructure

| Skill | Purpose |
|-------|---------|
| `/create-pi-host` | Bootstrap new Raspberry Pi cluster node |
| `/kde-extract` | Extract KDE settings to plasma-manager config |

---

## Container Deployment Pattern

1. Define container in `hosts/<host>/containers.nix`
2. Create encrypted env → `/encrypt-secret`
3. Create DNS record → `/add-dns-record`
4. Configure Caddy routes → `/add-caddy-route`
5. Verify: `just remote-dry-build <host>`
6. Deploy: `just remote-rebuild <host>`

---

## MCP Servers

| MCP | Purpose |
|-----|---------|
| **nixos** | NixOS/Home Manager/Darwin options search |
| **postgres-pilaster** | Pilaster database queries |
| **postgres-monolith** | Monolith database queries |
| **postgres-zenith** | Zenith database queries |

---

## Verification Checklist

Before completing any task:

- [ ] `just remote-dry-build <target>` passes
- [ ] No unencrypted secrets in commit
- [ ] Container images pinned (no `:latest`)
- [ ] DNS records created if needed
- [ ] Gatus monitoring updated for new services

---

## Documentation

- **Format:** Material for MkDocs
- **Nix formatting:** alejandra
- **CI validation:** `just check`

---

## Related

- [Ruinous Agents](https://agents.ruinous.ai/llms.txt) - Global agent ecosystem
- [NIXEY SME](https://agents.ruinous.ai/smes/nixey/) - Full infrastructure expertise
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) - Agent framework
