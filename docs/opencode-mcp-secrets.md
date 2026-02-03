# OpenCode MCP Server Secrets

This document describes the pattern for injecting file-based secrets into OpenCode MCP server configurations using agenix and Infisical.

## Overview

OpenCode supports two variable substitution patterns in configuration:

| Syntax | Source | Use Case |
|--------|--------|----------|
| `{env:VAR_NAME}` | Environment variable | Simple setups, CI/CD |
| `{file:/path/to/secret}` | File contents | Production, NixOS with agenix |

The `{file:...}` syntax is preferred for NixOS deployments because:
- Secrets are managed declaratively via agenix
- No environment variable pollution
- Secrets are encrypted at rest and decrypted only at runtime
- Works with Infisical for centralized secret management

## Architecture

```
Infisical (/shared, /services/*, /hosts/*)
    │
    ▼ (agenix generate)
secrets/generated/nixos/<host>/*.age
    │
    ▼ (agenix rekey)
secrets/nixos/<host>/*.age (encrypted for host keys)
    │
    ▼ (NixOS activation)
/run/agenix/<secret_name> (decrypted at runtime)
    │
    ▼ (OpenCode startup)
opencode.json: {file:/run/agenix/<secret_name>}
```

## Global MCP Server Secrets

Global secrets apply to all OpenCode sessions on a host. They are configured at the host level and shared across all projects.

### Step 1: Add Secrets to Infisical

```bash
PROJECT_ID="f95d3144-22bb-4c95-9ee8-f3319d4924d5"

# Shared secrets (used by multiple services)
infisical secrets set GITHUB_TOKEN="ghp_..." \
  --env=homelab --path=/shared --projectId=$PROJECT_ID

infisical secrets set TODOIST_API_TOKEN="..." \
  --env=homelab --path=/shared --projectId=$PROJECT_ID
```

### Step 2: Create Agenix Entries

Create `hosts/<hostname>/opencode.nix`:

```nix
# OpenCode MCP server secrets
{config, ...}: {
  ruinous.infisical.enable = true;

  # GitHub token - from /shared
  age.secrets.<hostname>_opencode_github_token = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "GITHUB_TOKEN";
      path = "/shared";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Todoist token - from /shared
  age.secrets.<hostname>_opencode_todoist_token = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "TODOIST_API_TOKEN";
      path = "/shared";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };
}
```

### Step 3: Configure MCP Servers

In the home-manager configuration (`hosts/<hostname>/users/<user>/home-configuration.nix`):

```nix
{config, osConfig, lib, pkgs, ...}: {
  ruinous.ruinage.assistants.opencode = {
    enable = true;

    # Override default MCP servers with file-based secrets
    mcpServers = lib.mkForce {
      github = {
        type = "remote";
        url = "https://api.githubcopilot.com/mcp/";
        oauth = false;
        headers = {
          "Authorization" = "Bearer {file:${osConfig.age.secrets.<hostname>_opencode_github_token.path}}";
        };
      };

      todoist = {
        type = "remote";
        url = "https://ai.todoist.net/mcp";
        headers = {
          "Authorization" = "Bearer {file:${osConfig.age.secrets.<hostname>_opencode_todoist_token.path}}";
        };
      };

      forgejo = {
        type = "local";
        command = [
          "${pkgs.forgejo-mcp}/bin/forgejo-mcp"
          "--transport" "stdio"
          "--url" "https://forge.example.com"
          "--token" "{file:${osConfig.age.secrets.<hostname>_opencode_forgejo_token.path}}"
        ];
      };
    };
  };
}
```

### Step 4: Generate and Deploy

```bash
# Generate secrets from Infisical
agenix generate -a

# Rekey for all hosts
agenix rekey -a

# Stage secrets
git add secrets/

# Verify build
just check <hostname>

# Deploy
just deploy <hostname>
```

## Project-Level MCP Server Secrets

Project-level secrets are specific to individual OpenCode projects. They can override or supplement global secrets.

### Option 1: Environment File Injection

Use the existing `environmentFiles` pattern with project-specific `.env.age` files:

```nix
ruinous.ruinage.projects.my-project = {
  repo = "my-project";
  assistants.opencode = {
    enable = true;
    port = 9500;
    # Project-specific environment file
    environmentFiles = [
      config.age.secrets.chassis_opencode_project_myproject_env.path
    ];
  };
};
```

The environment file can contain:
```
# Project-specific API keys
MY_PROJECT_API_KEY=secret123
DATABASE_URL=postgres://...
```

Then reference in project's `.opencode/oh-my-opencode.jsonc`:
```jsonc
{
  "mcps": {
    "my-custom-mcp": {
      "type": "local",
      "command": ["my-mcp", "--token", "{env:MY_PROJECT_API_KEY}"]
    }
  }
}
```

### Option 2: Project-Specific Secret Files

For projects that need file-based secrets (not environment variables):

#### Infisical Path Structure

```
/hosts/<hostname>/<project>/
├── DATABASE_URL
├── API_KEY
└── WEBHOOK_SECRET
```

#### Agenix Configuration

```nix
# In hosts/<hostname>/projects/<project>.nix
{config, ...}: {
  age.secrets.chassis_project_myproject_api_key = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "API_KEY";
      path = "/hosts/chassis/myproject";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };
}
```

#### Project OpenCode Config

In the project's `.opencode/oh-my-opencode.jsonc`:

```jsonc
{
  // Reference the deployed secret file
  // Path is known at build time from Nix
  "mcps": {
    "project-specific-mcp": {
      "type": "local", 
      "command": ["my-mcp", "--api-key", "{file:/run/agenix/chassis_project_myproject_api_key}"]
    }
  }
}
```

### Option 3: Nix-Managed Project MCP Overrides

For full declarative control, override MCP servers per-project in Nix:

```nix
ruinous.ruinage.projects.secure-project = {
  repo = "secure-project";
  assistants.opencode = {
    enable = true;
    port = 9600;
    
    # Project-specific MCP server overrides
    mcpServers = {
      # Add a project-specific MCP
      internal-api = {
        type = "remote";
        url = "https://api.internal.example.com/mcp";
        headers = {
          "Authorization" = "Bearer {file:${osConfig.age.secrets.chassis_project_secure_api_token.path}}";
        };
      };
      
      # Override global github with project-specific token
      github = {
        type = "remote";
        url = "https://api.githubcopilot.com/mcp/";
        oauth = false;
        headers = {
          "Authorization" = "Bearer {file:${osConfig.age.secrets.chassis_project_secure_github_token.path}}";
        };
      };
    };
  };
};
```

## Secret Hierarchy

Secrets should be organized by scope:

| Infisical Path | Scope | Example |
|----------------|-------|---------|
| `/shared/` | All services, all hosts | `GITHUB_TOKEN`, `ANTHROPIC_API_KEY` |
| `/services/<service>/` | One service, all hosts | `/services/opencode/CUSTOM_KEY` |
| `/hosts/<host>/<service>/` | One service, one host | `/hosts/chassis/opencode/LOCAL_KEY` |
| `/hosts/<host>/<project>/` | One project, one host | `/hosts/chassis/myproject/API_KEY` |

## Troubleshooting

### Secret Not Found

```bash
# Check if secret exists at runtime
sudo ls -la /run/agenix/

# Verify secret ownership
sudo stat /run/agenix/<secret_name>
```

### Permission Denied

Ensure the secret has correct ownership in Nix config:
```nix
age.secrets.<name> = {
  # ...
  mode = "400";
  owner = "<username>";  # Must match the user running opencode
  group = "users";
};
```

### Build Fails with Conflicting Definitions

Use `lib.mkForce` to override default MCP servers:
```nix
mcpServers = lib.mkForce { ... };
```

### Secret Value is Empty

1. Verify Infisical has the secret:
   ```bash
   infisical secrets get SECRET_NAME --env=homelab --path=/shared --plain
   ```

2. Regenerate and rekey:
   ```bash
   agenix generate -a
   agenix rekey -a
   ```

## Reference Implementation

See `hosts/chassis/opencode.nix` and `hosts/chassis/users/jmeskill/home-configuration.nix` for a working example of global MCP server secrets.

## Related Documentation

- [Encrypt Secret Skill](../.opencode/skills/encrypt-secret/README.md) - Creating secrets in Infisical
- [Secrets README](../secrets/README.md) - Agenix patterns
- [OpenCode Official Docs](https://opencode.ai/docs/config#files) - `{file:...}` syntax
