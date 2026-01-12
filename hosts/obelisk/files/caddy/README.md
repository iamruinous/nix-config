# Obelisk Caddy Routes

Hostname catalog for `Caddyfile.age` - enables searching without decryption.

**Host:** obelisk (AI/inference server)

## Domain Mappings

| Domain | Service | Description |
|--------|---------|-------------|
| `ai.svc.farmhouse.meskill.network` | open-webui | Open WebUI (internal network) |
| `ai.meskill.farm` | open-webui | Open WebUI (external) |
| `ollama.svc.farmhouse.meskill.network` | ollama | Ollama API (internal network) |
| `ollama.meskill.farm` | ollama | Ollama API (external) |
| `obelisk.svc.farmhouse.meskill.network` | static files | SPICE HTML5 client (internal) |
| `obelisk.meskill.farm` | static files | SPICE HTML5 client (external) |

## Notes

- SPICE HTML5 client serves static files from `/static/spice-html5`
- Ollama requires `Host: localhost` header upstream
- Uses HTTP/1.1 only (`servers { protocols h1 }`)
- `svc.farmhouse.meskill.network` is internal service network
