# OpenCode Environment Secrets

**File:** `env.age`  
**Owner:** jmeskill (user secret)  
**Mode:** 400  
**Referenced by:** `hosts/chassis/users/jmeskill/home-configuration.nix`

## Purpose

Environment variables for OpenCode web services running on chassis. Shared across all OpenCode project services.

## Contents

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | API key for Anthropic Claude models |
| `OPENAI_API_KEY` | API key for OpenAI models |
| `GOOGLE_API_KEY` | API key for Google AI models (Gemini) |
| `XAI_API_KEY` | API key for xAI models (Grok) |
| `OPENROUTER_API_KEY` | API key for OpenRouter (multi-model gateway) |
| `EXA_API_KEY` | API key for Exa web search |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub PAT for repository access |
| `SUPABASE_ACCESS_TOKEN` | Supabase access token (for Dossiq) |

## Usage

This environment file is loaded by all OpenCode systemd user services:

```nix
opencode-projects = {
  environmentFiles = [
    config.age.secrets.chassis_opencode_env.path
  ];
  # ...
};
```

Each project service (`opencode-web-nix`, `opencode-web-codey`, etc.) inherits these variables.

## Projects Using This Secret

| Project | Port | Service |
|---------|------|---------|
| nix | 9500 | `opencode-web-nix.service` |
| n8n | 9501 | `opencode-web-n8n.service` |
| dossiq | 9502 | `opencode-web-dossiq.service` |
| codey | 9503 | `opencode-web-codey.service` |
| kimaki-discord | 9504 | `opencode-web-kimaki-discord.service` |
| messy-discord | 9505 | `opencode-web-messy-discord.service` |

## Related

- `hosts/chassis/users/jmeskill/home-configuration.nix` - OpenCode projects configuration
- `modules/home/default/ai-cli/opencode-projects.nix` - OpenCode projects module
- `hosts/chassis/caddy.nix` - Caddy reverse proxy configuration
