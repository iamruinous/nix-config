# MCP Server Registry

This document serves as the registry for Model Context Protocol (MCP) servers used within the `nix-config` project. It documents the active servers and provides instructions for configuring them across our primary agents: `claude-code`, `gemini-cli`, and `opencode`.

## Active Servers

### 1. NixOS MCP (`mcp-nixos`)
**Purpose:** Provides search capabilities for NixOS packages, options, and Home Manager configurations.
**Source:** `uvx mcp-nixos`
**Type:** `stdio`

### 2. Farm Gateway (`mcp-farm`)
**Purpose:** Centralized MCP gateway for the `meskill.farm` infrastructure, providing access to remote resources or aggregated context.
**Source:** `https://mcp.meskill.farm/sse`
**Type:** `sse`

### 3. Postgres MCP (`postgres-mcp`)
**Purpose:** Direct SQL execution access to project databases.
**Source:** `uvx postgres-mcp`
**Type:** `stdio`
**Instances:**
*   `postgres-pilaster`
*   `postgres-monolith`
*   `postgres-zenith`
*   `postgres-tty-ruinous-social`
**Configuration:** Requires environment variables for connection strings (e.g., `PILASTER_POSTGRES_DATABASE_URI`).

### 4. Todoist (`todoist`)
**Purpose:** Task management integration.
**Source:** Global / `uvx @modelcontextprotocol/server-todoist`
**Type:** `stdio`
**Configuration:** Requires `TODOIST_API_TOKEN` (usually managed globally).

---

## Agent Configuration Instructions

### Prerequisites
*   **uv:** Most stdio servers run via `uvx`. Ensure `uv` is installed in your environment.

### 1. Claude Code
Claude Code reads configuration automatically from the `.mcp.json` file in the project root.

**Configuration File:** `./.mcp.json`

**Setup:**
1.  Ensure `.mcp.json` exists in the project root.
2.  Ensure required environment variables (e.g., for Postgres) are loaded in the shell where `claude` is started.

### 2. Gemini CLI
Gemini CLI requires configuration in `.gemini/settings.json`.

**Configuration File:** `./.gemini/settings.json`

**Setup:**
Add the `mcpServers` block to your settings file.

```json
{
  "mcpServers": {
    "mcp-nixos": {
      "command": "uvx",
      "args": ["mcp-nixos"]
    },
    "mcp-farm": {
      "type": "sse",
      "url": "https://mcp.meskill.farm/sse"
    },
    "postgres-pilaster": {
      "command": "uvx",
      "args": ["postgres-mcp", "--access-mode=unrestricted"],
      "env": {
        "DATABASE_URI": "${PILASTER_POSTGRES_DATABASE_URI}"
      }
    }
    // Add other postgres instances as needed
  }
}
```

*Note: Variable substitution like `${VAR}` might not be natively supported in all JSON parsers used by Gemini CLI. Verify if explicit values are needed or if the environment is inherited.*

### 3. OpenCode (VS Code / Cursor)
OpenCode-compatible editors typically support `.mcp.json` or a specific workspace configuration.

**Configuration File:** `./.mcp.json` (Standard) or `.vscode/settings.json` (legacy).

**Setup:**
1.  Most modern MCP implementations for VS Code will detect `.mcp.json` in the root.
2.  If manual configuration is required in `settings.json`:

```json
"mcp.servers": {
    "mcp-nixos": {
        "command": "uvx",
        "args": ["mcp-nixos"]
    }
    // ... map other servers similarly
}
```

## Environment Variables
The Postgres MCP servers rely on environment variables. These are typically managed via `.envrc` (direnv) or the shell environment.

*   `PILASTER_POSTGRES_DATABASE_URI`
*   `MONOLITH_POSTGRES_DATABASE_URI`
*   `ZENITH_POSTGRES_DATABASE_URI`
*   `TTY_RUINOUS_SOCIAL_POSTGRES_DATABASE_URI`
