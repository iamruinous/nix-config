# nix-config

> Declarative NixOS/Darwin infrastructure for 24 hosts.

**LLM Context:** [llms.txt](llms.txt) | **Full Docs:** [agents.ruinous.ai](https://agents.ruinous.ai)

---

## NIXEY - Infrastructure SME

This repository is the domain of **[NIXEY](https://agents.ruinous.ai/smes/nixey/)**, the infrastructure subject matter expert for ruinous.ai.

**NIXEY provides:** Infrastructure context, deployment patterns, architecture decisions  
**Sisyphus executes:** Via oh-my-opencode orchestration and specialized agents

### Specialized Agents

| Agent | Domain | Triggers |
|-------|--------|----------|
| **agenix** | Secrets (.age files), encryption, rekeying | encrypt, secret, .age |
| **cfnix** | Cloudflare DNS, tunnels, SSL | DNS, tunnel, cloudflare |
| **containnix** | Docker containers, networks, Caddy | container, deploy, service |
| **nix-packager** | Nix package creation | package, derivation |

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

| Skill | Purpose |
|-------|---------|
| `/deploy-container` | Full container deployment workflow |
| `/create-db-<host>` | PostgreSQL database (pilaster, monolith, zenith) |
| `/setup-tunnel` | Cloudflare tunnel configuration |
| `/pr` | Branch, commit, create PR |
| `/automerge` | Branch, commit, create PR, merge |
| `/create-pi-host` | Bootstrap new Raspberry Pi cluster node |

---

## Container Deployment Pattern

1. Define container in `hosts/<host>/containers.nix`
2. Create encrypted env → delegate to **agenix**
3. Create DNS record → delegate to **cfnix**
4. Configure Caddy routes → `services.docker-caddy` or Caddyfile.age
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
