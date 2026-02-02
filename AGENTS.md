# nix-config

> Declarative NixOS/Darwin infrastructure for 24 hosts.

**LLM Context:** [llms.txt](llms.txt) | **Full Docs:** [agents.ruinous.ai](https://agents.ruinous.ai)

---

## NIXEY - Infrastructure SME

This repository is the domain of **[NIXEY](https://agents.ruinous.ai/smes/nixey/)**, the infrastructure subject matter expert for ruinous.ai.

**NIXEY provides:** Infrastructure context, deployment patterns, architecture decisions  
**Sisyphus executes:** Via oh-my-opencode orchestration and skills

---

## Public Repository Notice

⚠️ **This is a public repository.** Be discreet with sensitive information:

| Keep Private | OK to Include |
|--------------|---------------|
| API keys, tokens, passwords | Hostnames (already in config) |
| Infisical/vault project IDs | Service names and architecture |
| Internal URLs with auth tokens | Network topology |
| Database credentials | General deployment patterns |

When creating issues or PRs, avoid including actual secret values, project IDs, or authenticated URLs. Reference secrets by name, not value.

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
# Hosts (auto-detect local/remote, Darwin/NixOS)
just check [host]              # Verify build (dry-build)
just deploy [host]             # Deploy configuration
just build [host]              # Build without switching
just install                   # Install Nix + nix-darwin

# Validation
just canary                    # Dry-build representative hosts

# Secrets
just unlock                    # Unlock agenix identity
just peek <secret>             # View encrypted secret
just encrypt <secret>          # Create/edit encrypted secret
just rekey                     # Re-encrypt all secrets

# RPi Images
just sd-image <host>           # Build SD image for Raspberry Pi
just sd-flash <host> <device>  # Flash SD image to device

# Op Management (Isolated Development Sessions)
0p new <op-id> --repo <repo> --deck <deck>  # Create new Op
0p list                                      # List all Ops
0p status <op-id>                            # Show Op details
0p attach <op-id>                            # Attach to Op's tmux session
0p suspend <op-id>                           # Suspend active Op
0p resume <op-id>                            # Resume suspended Op
0p complete <op-id>                          # Complete and cleanup Op
```

For user passwords and advanced operations, see `just --list`.

### Deployment Workflow

1. Make changes to host configuration
2. Verify build: `just check [host]`
3. Deploy: `just deploy [host]`

---

## Skills Catalog

Skills are invoked with `/skill-name <arguments>`. If required arguments are missing, the agent will use `mcp_question` to interactively gather them.

### Secrets Management

| Skill | Trigger Phrase | What It Does |
|-------|----------------|--------------|
| `/encrypt-secret` | "create secret", "encrypt env file", "add credentials" | Create or update an encrypted `.age` file using agenix |
| `/view-secret` | "show secret", "decrypt", "view credentials" | Decrypt and display contents of an `.age` file |
| `/rekey-secrets` | "rekey", "rotate keys", "new host added" | Re-encrypt all secrets after modifying `secrets.nix` or host keys |

### DNS & Networking

| Skill | Trigger Phrase | What It Does |
|-------|----------------|--------------|
| `/add-dns-record` | "add DNS", "create CNAME", "A record", "point domain", "cfcli add", "DNS entry" | Add CNAME/A record to Cloudflare via cfcli |
| `/setup-cloudflare-tunnel` | "external access", "expose service", "create tunnel", "public access" | Create and configure a Cloudflare Tunnel for public access |
| `/add-caddy-route` | "reverse proxy", "add route", "proxy to container", "Caddy route" | Add reverse proxy route to encrypted Caddyfile |

### Database & Container Deployment

| Skill | Trigger Phrase | What It Does |
|-------|----------------|--------------|
| `/deploy-container` | "deploy new service", "add container", "full deployment" | Complete workflow: secrets + Caddy + DNS + container definition |
| `/initialize-pgdb` | "create database", "new postgres db", "init db" | Create PostgreSQL database and user on any configured host |

### Nix Packaging

| Skill | Trigger Phrase | What It Does |
|-------|----------------|--------------|
| `/add-package` | "add package from URL", "package from GitHub", "create package from repo" | Analyze project from URL/path and auto-detect build system to create Nix package |
| `/create-nix-package` | "package this", "create nix package", "add to packages/" | Create new Nix package from source code or binary (manual type selection) |
| `/wrap-shell-script` | "wrap script", "nixify bash script" | Convert shell script into reproducible Nix package |
| `/update-package` | "update package to", "bump version", "new release" | Update package version with automatic hash resolution |
| `/update-flake-input` | "update flake input", "update ruinagents", "update budgey" | Update versioned flake inputs (ruinagents, budgey-*) to latest tagged version |

### Ruinage & OpenCode Projects

Projects are managed through the `ruinous.ruinage` module, which provides unified configuration for OpenCode, Kimaki, and other assistants.

| Skill | Trigger Phrase | What It Does |
|-------|----------------|--------------|
| `/add-opencode-project` | "add project to opencode", "new opencode project", "opencode web service" | Add project with DNS, Caddy, Gatus monitoring, and deployment |

**Deprecated patterns:**
- `ruinous.ai-cli.opencode-projects` → use `ruinous.ruinage.projects`
- `ruinous.ai-cli.kimaki` → use `ruinous.ruinage.assistants.kimaki`

### Infrastructure

| Skill | Trigger Phrase | What It Does |
|-------|----------------|--------------|
| `/nix-deploy` | "deploy", "rebuild", "just deploy", "remote-rebuild", "apply changes" | Deploy NixOS/Darwin configuration to local or remote host |
| `/create-pi-host` | "new raspberry pi", "add pi to cluster" | Bootstrap new Raspberry Pi cluster node configuration |
| `/kde-extract` | "extract KDE settings", "plasma config" | Extract KDE/Plasma settings to plasma-manager Nix config |

### macOS Window Management

| Skill | Trigger Phrase | What It Does |
|-------|----------------|--------------|
| `/add-aerospace-entry` | "add aerospace rule", "assign app to workspace", "aerospace window" | Add AeroSpace window rule to assign app/window to workspace (macOS only) |

### Skill Selection Guide

**Starting a new service?**
1. `/deploy-container` - Full workflow (recommended for new services)
2. Or manually: `/initialize-pgdb` → `/encrypt-secret` → `/add-caddy-route` → `/add-dns-record`

**Updating existing code?**
- `/update-package <name> <version>` - For packages in `packages/`
- `/update-flake-input <name>` - For versioned flake inputs (ruinagents, budgey-*)

**Working with secrets?**
- Always run `agenix-helper unlock` first
- `/encrypt-secret` for new secrets
- `/view-secret` to inspect existing
- `/rekey-secrets` after changing `secrets.nix`

**Need external access?**
- Internal only: `/add-caddy-route`
- Public access: `/setup-cloudflare-tunnel` + `/add-dns-record`

**Need a database?**
- `/initialize-pgdb <host> <db_name>` - Creates database and user on any host

---

## Project Configuration

Projects are now managed through the unified `ruinous.ruinage` module:

```nix
ruinous.ruinage.projects.my-project = {
  repo = "my-project";
  owner = "iamruinous";  # default
  forge = "forge.meskill.farm";  # default
  namespaces.ruinage.enable = true;
  assistants.opencode = {
    enable = true;
    port = 9500;
    caddy.fqdn = "my-project.oc.ruinous.ai";
  };
  tmuxp.enable = true;
  direnv.enable = true;
  budgey.enable = true;
};
```

## Container Deployment Pattern

1. Define container in `hosts/<host>/containers.nix`
2. Create encrypted env → `/encrypt-secret`
3. Create DNS record → `/add-dns-record`
4. Configure Caddy routes → `/add-caddy-route`
5. Verify: `just check <host>`
6. Deploy: `just deploy <host>`

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

- [ ] `just check <target>` passes
- [ ] No unencrypted secrets in commit
- [ ] Container images pinned (no `:latest`)
- [ ] DNS records created if needed
- [ ] Gatus monitoring updated for new services

---

## Documentation

- **Format:** Material for MkDocs
- **Nix formatting:** alejandra
- **CI validation:** `just canary`

---

## Related

- [Ruinous Agents](https://agents.ruinous.ai/llms.txt) - Global agent ecosystem
- [NIXEY SME](https://agents.ruinous.ai/smes/nixey/) - Full infrastructure expertise
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) - Agent framework
