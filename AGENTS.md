# nix-config - Local Agent Context

**Type:** NixOS/Darwin Infrastructure  
**Stack:** Nix Flakes, Blueprint, Agenix, Home Manager  
**Purpose:** Declarative configuration management for 24 hosts across NixOS and macOS

---

## Commands

| Command | Description |
|---------|-------------|
| `nixos-rebuild switch --flake .#<hostname>` | Apply NixOS configuration |
| `darwin-rebuild switch --flake .#<hostname>` | Apply macOS configuration |
| `make dry-build` | Dry-build local host configuration |
| `make remote-rebuild remotehost=<hostname>` | Deploy to remote host |
| `make remote-dry-build remotehost=<hostname>` | Verify remote build without applying |
| `nix build .#<package-name>` | Build a package |
| `agenix-helper unlock` | Unlock secrets for editing |
| `agenix-helper lock` | Lock secrets after editing |

---

## Project-Specific Agents

| Agent | Purpose | Triggers |
|-------|---------|----------|
| **agenix** | Secrets management (.age files), rekeying, encryption | encrypt, rekey, secrets, .age |
| **cfnix** | Cloudflare DNS records & Tunnel configuration | DNS, tunnel, cloudflare |
| **containnix** | Docker/OCI container deployment, networking, Caddy proxy | container, docker, service, deploy |
| **nix-packager** | Nix package creation and conversion | package, derivation |

Agent definitions: `.claude/agents/`

---

## Architecture

```
nix-config/
├── hosts/           # 24 host configurations (NixOS, Darwin, microVMs)
├── modules/         # Reusable modules
│   ├── nixos/       # NixOS-specific (default/, desktop/)
│   ├── darwin/      # macOS-specific
│   └── home/        # Home Manager modules
├── packages/        # Custom Nix packages
├── secrets/         # Encrypted secrets (agenix)
├── users/           # User configurations
├── devshells/       # Development environments
└── .claude/         # Agent definitions and commands
```

### Host Breakdown
- **14 NixOS Servers** - Physical infrastructure, Raspberry Pi cluster
- **2 NixOS Thin Clients** - High Availability pair
- **1 Cloud VPS** - Remote services
- **2 NixOS Workstations** - Desktop & Laptop
- **2 NixOS MicroVMs** - Development environments
- **3 macOS Systems** - Development workstations

---

## Domain Knowledge

### Secrets Management (agenix)

**CRITICAL:** Never commit unencrypted secrets.

```bash
# Workflow for editing secrets
agenix-helper unlock          # Enter passphrase once
agenix view file.age > tmp/temp.txt
# ... edit tmp/temp.txt ...
rm file.age && agenix edit -i tmp/temp.txt file.age
rm tmp/temp.txt && agenix rekey -a
agenix-helper lock            # When done
```

### Container Deployment Pattern

1. Define container in `hosts/<hostname>/containers.nix`
2. Create encrypted env file → delegate to `agenix`
3. Create DNS record → delegate to `cfnix`
4. Update Caddyfile → delegate to `agenix` (if encrypted)
5. Verify: `make remote-dry-build remotehost=<hostname>`

### Container Networks

| Network | Purpose |
|---------|---------|
| `servicenet` | Inter-container & Caddy access |
| `datanet` | Internal databases (no external access) |
| `proxynet` | Host port binding (use sparingly) |

### Docker Caddy Module (Declarative Routes)

Use `services.docker-caddy` to define Caddy routes declaratively in Nix. The module:
- Separates secrets (ACME credentials) from route configuration
- Generates Caddyfile at activation time
- Makes routes self-documenting and searchable in Nix code

**Secrets file** (encrypted with agenix):
```
{
  acme_dns cloudflare YOUR_API_TOKEN
  email admin@example.com
}
```

**Route configuration** (in containers.nix or similar):
```nix
services.docker-caddy = {
  enable = true;
  secretsFile = config.age.secrets.caddy_secrets.path;
  email = "admin@meskill.network";

  # Simple reverse proxy routes
  routes = {
    "app.example.com" = {
      upstream = "app:8080";
      description = "Main application";
    };
    "ollama.example.com" = {
      upstream = "ollama:11434";
      description = "Ollama API";
      extraConfig = ''
        header_up Host localhost
      '';
    };
  };

  # Complex routes with raw Caddy config
  rawRoutes = {
    "matrix.example.com" = {
      description = "Matrix homeserver";
      config = ''
        reverse_proxy /_matrix/* synapse:8008
        reverse_proxy /_synapse/* synapse:8008
      '';
    };
  };
};
```

**Module location:** `modules/nixos/server/docker-caddy.nix`

**Legacy:** Some hosts still use `Caddyfile.age` directly with companion `README.md` files for documentation. Migrate to the module when updating those hosts.

---

### Package Creation (Preferred Pattern)

Use external shell scripts with `substitute`:

```
packages/<name>/
├── default.nix      # stdenv.mkDerivation + substitute
├── <name>.sh        # Actual shell script (no escaping issues)
└── README.md        # Documentation
```

Key points:
- Use `@placeholder@` syntax for paths
- `propagatedBuildInputs` for runtime deps
- Full paths in scripts (`@pkg@/bin/command`)

---

## Slash Commands

| Command | Description |
|---------|-------------|
| `/create-db-<host>` | Create PostgreSQL database (pilaster, monolith, zenith) |
| `/create-pi-host` | Bootstrap new Raspberry Pi cluster host |
| `/automerge` | Branch, commit, create PR, and merge in one flow |
| `/pr` | Branch, commit, create PR (without auto-merge) |
| `/refresh-readme` | Show README.md changes and refresh |

Command definitions: `.claude/commands/`

---

## MCP Servers

| MCP | Purpose |
|-----|---------|
| **nixos** | NixOS/Home Manager/Darwin options search |
| **postgres-pilaster** | Pilaster database queries |
| **postgres-monolith** | Monolith database queries |
| **postgres-zenith** | Zenith database queries |

---

## Development Standards

| Standard | Tool/Command |
|----------|--------------|
| **Nix Formatting** | `alejandra` |
| **CI Validation** | `make check` |
| **Modularity** | Prefer reusable modules in `modules/` over ad-hoc config |
| **Container Images** | Pin tags (no `:latest`) |

---

## Verification

Before completing any task:

- [ ] `make remote-dry-build remotehost=<target>` passes
- [ ] No unencrypted secrets in commit
- [ ] Images pinned (no `:latest` tags)
