# Caddy Environment Secrets

**File:** `env.age`  
**Owner:** caddy:caddy  
**Mode:** 400  
**Referenced by:** `hosts/chassis/caddy.nix`

## Purpose

Environment variables for Caddy's ACME DNS-01 challenge with Cloudflare. Used to automatically obtain and renew TLS certificates for `*.oc.ruinous.ai` domains.

## Contents

| Variable | Description |
|----------|-------------|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token with Zone:DNS:Edit permissions for `ruinous.ai` zone |

## Usage

The Caddy service loads this file via `environmentFile` and uses the token in its global config:

```caddy
{
  acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
}
```

## Token Requirements

The Cloudflare API token needs:
- **Permissions:** Zone → DNS → Edit
- **Zone Resources:** Include → Specific zone → `ruinous.ai`

## Related

- `hosts/chassis/caddy.nix` - Caddy configuration that uses this secret
- Cloudflare Dashboard → API Tokens for token management
