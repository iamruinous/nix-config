# Zenith Caddy Routes

Hostname catalog for `Caddyfile.age` - enables searching without decryption.

**Host:** zenith (AI/ML workstation)

## Domain Mappings

| Domain | Service | Description |
|--------|---------|-------------|
| `ai.x.meskill.farm` | open-webui | Open WebUI chat interface |
| `zenith.ollama.meskill.farm` | ollama | Ollama API (zenith-specific) |
| `ollama.x.meskill.farm` | ollama | Ollama API (generic) |
| `mcp.x.meskill.farm` | mcp-gateway | Model Context Protocol gateway |
| `opencode.meskill.farm` | host.docker.internal:18080 | OpenCode development server |
| `timeline-int.meskill.farm` | dawarich-app | Dawarich timeline (internal) |
| `timeline.meskill.farm` | dawarich-app | Dawarich timeline (external) |
| `nominatim.meskill.farm` | nominatim | Nominatim geocoding |
| `nominatim.x.meskill.farm` | nominatim | Nominatim geocoding (alt) |

## Notes

- Internal suffix `-int` indicates internal-only access
- `x.meskill.farm` subdomain pattern used for experimental/dev services
- Ollama requires `Host: localhost` header upstream
