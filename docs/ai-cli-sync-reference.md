# AI CLI Configuration Sync Reference

This document provides a comprehensive reference for which AI CLI configuration files can be safely stored in a public repository, which require encryption, and which should not be synced at all.

## Quick Reference

| Symbol | Meaning |
|--------|---------|
| :white_check_mark: | Safe for public repo |
| :lock: | Requires encryption (agenix) |
| :warning: | Needs templating (contains personal info) |
| :x: | Do not sync (machine-specific/ephemeral) |

---

## Gemini CLI (`~/.gemini/`)

| File/Directory | Sync? | Notes |
|----------------|-------|-------|
| `settings.json` | :white_check_mark: | MCP servers, UI preferences, output format |
| `GEMINI.md` | :white_check_mark: | Project memory/context file (per-project) |
| `extensions/` | :x: | Install manually via `gemini extension install <name>` |
| `google_accounts.json` | :warning: | Contains email address - use Nix templating |
| `oauth_creds.json` | :lock: | OAuth access/refresh tokens - **ENCRYPT** |
| `mcp-oauth-tokens.json` | :lock: | MCP OAuth tokens (Todoist, etc.) - **ENCRYPT** |
| `installation_id` | :x: | Unique UUID per installation |
| `state.json` | :x: | Ephemeral UI state |
| `tmp/` | :x: | Session data, chat history, downloaded binaries |

### settings.json Structure

```json
{
  "security": {
    "auth": {
      "selectedType": "oauth-personal"
    }
  },
  "general": {
    "previewFeatures": true,
    "sessionRetention": { "enabled": true },
    "enablePromptCompletion": true,
    "disableAutoUpdate": true
  },
  "output": {
    "format": "text"
  },
  "ui": {
    "showMemoryUsage": true
  },
  "tools": {
    "shell": { "showColor": true }
  },
  "mcpServers": {
    "server-name": {
      "url": "https://example.com/mcp"
    }
  }
}
```

### Notes on MCP Servers

- URL-based MCP servers (like Todoist) are safe to include
- Local command-based MCP servers may have machine-specific paths
- Consider using environment variables or per-host configuration for local MCPs

---

## Claude Code (`~/.claude/`)

| File/Directory | Sync? | Notes |
|----------------|-------|-------|
| `settings.json` | :white_check_mark: | Permissions, sandbox settings, status line |
| `.credentials.json` | :lock: | Claude OAuth + MCP OAuth tokens - **ENCRYPT** |
| `statsig/` | :x: | Machine-specific telemetry/analytics |
| `todos/` | :x: | Session todo lists |
| `transcripts/` | :x: | Session transcripts |
| `history.jsonl` | :x: | Command history |
| `projects/` | :x: | Project-specific caches |
| `file-history/` | :x: | File change history |
| `debug/` | :x: | Debug logs |
| `plans/` | :x: | Session plans |
| `plugins/` | :x: | Plugin state |
| `session-env/` | :x: | Session environment snapshots |
| `shell-snapshots/` | :x: | Shell state snapshots |
| `stats-cache.json` | :x: | Statistics cache |
| `telemetry/` | :x: | Telemetry data |

### settings.json Structure

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "WebFetch",
      "Bash(git:*)",
      "Bash(gh pr:*)",
      "mcp__server-name__*"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)"
    ],
    "defaultMode": "acceptEdits"
  },
  "statusLine": {
    "type": "command",
    "command": "bunx -y ccstatusline@latest",
    "padding": 0
  },
  "sandbox": {
    "enabled": false,
    "autoAllowBashIfSandboxed": true
  },
  "alwaysThinkingEnabled": true,
  "includeCoAuthoredBy": false,
  "companyAnnouncements": [
    "Custom announcement message"
  ]
}
```

### .credentials.json Structure (ENCRYPTED)

This file contains sensitive OAuth tokens:
- `claudeAiOauth`: Claude API access/refresh tokens, subscription info
- `mcpOAuth`: OAuth tokens for various MCP servers (Todoist, n8n, etc.)

---

## OpenCode (`~/.config/opencode/` and `~/.local/share/opencode/`)

### Config Directory (`~/.config/opencode/`)

| File/Directory | Sync? | Notes |
|----------------|-------|-------|
| `opencode.json` | :white_check_mark: | Plugins, provider configuration |
| `oh-my-opencode.json` | :white_check_mark: | Agent model assignments |
| `package.json` | :white_check_mark: | Plugin manifest (can be generated) |
| `node_modules/` | :x: | Generated - run `bun install` |
| `bun.lock` | :x: | Generated lockfile |
| `.gitignore` | :x: | Generated |

### Data Directory (`~/.local/share/opencode/`)

| File/Directory | Sync? | Notes |
|----------------|-------|-------|
| `auth.json` | :lock: | OAuth tokens + API keys for all providers - **ENCRYPT** |
| `bin/` | :x: | Downloaded binaries (LSP servers, etc.) |
| `log/` | :x: | Log files |
| `snapshot/` | :x: | Session snapshots |
| `storage/` | :x: | Session storage |

### State Directory (`~/.local/state/opencode/`)

| File/Directory | Sync? | Notes |
|----------------|-------|-------|
| `model.json` | :x: | Last used model selection |
| `prompt-history.jsonl` | :x: | Prompt history |

### opencode.json Structure

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "oh-my-opencode",
    "opencode-openai-codex-auth",
    "opencode-gemini-auth@latest"
  ],
  "provider": {
    "openai": {
      "api": "codex",
      "name": "OpenAI",
      "models": {
        "gpt-5.2": { "name": "GPT-5.2" },
        "o3": { "name": "o3" },
        "o4-mini": { "name": "o4-mini" },
        "codex-1": { "name": "Codex-1" }
      }
    }
  }
}
```

### oh-my-opencode.json Structure

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  "google_auth": false,
  "agents": {
    "explore": {
      "model": "anthropic/claude-haiku-4-5"
    },
    "frontend-ui-ux-engineer": {
      "model": "anthropic/claude-opus-4-5"
    },
    "document-writer": {
      "model": "anthropic/claude-opus-4-5"
    },
    "multimodal-looker": {
      "model": "anthropic/claude-opus-4-5"
    }
  }
}
```

### auth.json Structure (ENCRYPTED)

Located at `~/.local/share/opencode/auth.json`, contains credentials for multiple providers:

```json
{
  "anthropic": {
    "type": "oauth",
    "refresh": "<REFRESH_TOKEN>",
    "access": "<ACCESS_TOKEN>",
    "expires": 1767515624817
  },
  "openai": {
    "type": "oauth",
    "refresh": "<REFRESH_TOKEN>",
    "access": "<JWT_ACCESS_TOKEN>",
    "expires": 1768273676996
  },
  "google": {
    "type": "oauth",
    "refresh": "<REFRESH_TOKEN>",
    "access": "<ACCESS_TOKEN>",
    "expires": 1767435378790
  },
  "openrouter": {
    "type": "api",
    "key": "<API_KEY>"
  },
  "opencode": {
    "type": "api",
    "key": "<API_KEY>"
  },
  "groq": {
    "type": "api",
    "key": "<API_KEY>"
  }
}
```

**Provider types:**
- `oauth`: Uses refresh/access token pairs with expiration
- `api`: Uses static API key

---

## Authentication Flow

### Initial Setup (Per Machine)

1. **Gemini**: Run `gemini auth login` to authenticate
2. **Claude**: Run `claude` and follow OAuth flow
3. **OpenCode**: Authentication handled by plugins

### Syncing Credentials

After authenticating on a new machine:

```bash
# Unlock agenix
agenix-helper unlock

# Update Gemini OAuth (from ~/.gemini/oauth_creds.json)
agenix edit -i ~/.gemini/oauth_creds.json files/configs/gemini/oauth_creds.json.age

# Update Gemini MCP OAuth (from ~/.gemini/mcp-oauth-tokens.json)  
agenix edit -i ~/.gemini/mcp-oauth-tokens.json files/configs/gemini/mcp-oauth-tokens.json.age

# Update Claude credentials (from ~/.claude/.credentials.json)
agenix edit -i ~/.claude/.credentials.json files/configs/claude/credentials.json.age

# Update OpenCode auth (from ~/.local/share/opencode/auth.json)
agenix edit -i ~/.local/share/opencode/auth.json files/configs/opencode/auth.json.age

# Rekey all secrets
agenix rekey -a

# Lock agenix
agenix-helper lock
```

### Token Expiration

OAuth tokens will expire periodically:
- **Gemini**: Access tokens expire ~1 hour, refresh tokens are long-lived
- **Claude**: Similar OAuth flow with refresh tokens
- **MCP OAuth**: Varies by provider (Todoist tokens are very long-lived)

When tokens expire, re-authenticate with the CLI tool and update the encrypted secrets.

---

## Home-Manager Integration

### Module Location

```
modules/home/default/ai-cli/
├── default.nix       # Imports all sub-modules
├── gemini.nix        # Gemini CLI configuration
├── claude-code.nix   # Claude Code configuration
└── opencode.nix      # OpenCode configuration
```

### Config Files Location

```
files/configs/
├── gemini/
│   ├── settings.json              # Public settings
│   ├── oauth_creds.json.age       # Encrypted OAuth
│   └── mcp-oauth-tokens.json.age  # Encrypted MCP OAuth
├── claude/
│   ├── settings.json              # Public settings
│   └── credentials.json.age       # Encrypted credentials
└── opencode/
    ├── opencode.json              # Public config
    ├── oh-my-opencode.json        # Public agent config
    └── auth.json.age              # Encrypted auth (OAuth + API keys)
```

### Enabling in Host Configuration

```nix
# In hosts/<hostname>/users/<user>/default.nix
{
  ruinous.ai-cli = {
    gemini.enable = true;
    claude-code.enable = true;
    opencode.enable = true;
  };
}
```

---

## Troubleshooting

### Credentials Not Working After Sync

1. Check if tokens have expired (re-authenticate if needed)
2. Verify agenix decryption: `ls -la /run/user/$(id -u)/agenix/`
3. Check file permissions (should be 600)

### MCP Servers Not Connecting

1. Verify MCP OAuth tokens are current
2. Check if MCP server URLs are accessible
3. For local MCPs, verify paths are correct for the host

### OpenCode Plugins Not Loading

1. Run `bun install` in `~/.config/opencode/`
2. Check if `node_modules/` was created
3. Verify plugin names in `opencode.json`

---

## Security Considerations

1. **Never commit unencrypted OAuth tokens**
2. **Review MCP server URLs** - only include trusted servers
3. **Audit permission lists** in Claude settings.json
4. **Use per-host secrets** if credentials differ between machines
5. **Rotate tokens periodically** for security

---

## Related Documentation

- [Agenix Usage](../README.md#secrets-management)
- [Home-Manager Modules](../modules/home/README.md)
- [Gemini CLI Docs](https://github.com/google-gemini/gemini-cli)
- [Claude Code Docs](https://docs.anthropic.com/claude-code)
- [OpenCode Docs](https://opencode.ai/docs)
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)
