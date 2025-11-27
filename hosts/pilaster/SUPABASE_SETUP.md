# Supabase Setup Guide for Pilaster

This guide explains how to complete the Supabase setup on the pilaster host.

## Overview

A full Supabase stack has been configured with 13 services:
- **supabase-db** - Dedicated PostgreSQL with Supabase extensions (supabase/postgres:15.8.1.085)
- **supabase-studio** - Web dashboard
- **supabase-kong** - API gateway
- **supabase-auth** - Authentication (GoTrue)
- **supabase-rest** - REST API (PostgREST)
- **supabase-realtime** - WebSocket service
- **supabase-storage** - File storage
- **supabase-imgproxy** - Image transformation
- **supabase-meta** - Postgres metadata API
- **supabase-functions** - Edge functions
- **supabase-analytics** - Logging (Logflare)
- **supabase-vector** - Log routing
- **supabase-pooler** - Connection pooler (Supavisor)

A dedicated **supabase-db** container using the official `supabase/postgres:15.8.1.085` image provides all required PostgreSQL extensions (pgsodium, pg_graphql, pg_net, etc.) pre-installed. The existing **postgres** container remains available for other services like Authentik.

## Prerequisites

1. Generate JWT keys and secrets (see [Generating Secrets](#generating-secrets))
2. Access to agenix for encrypting environment files
3. Domain configured: `supabase.meskill.farm`

## Step 1: Generate Secrets

### Generate JWT Secret (64 characters)
```bash
head -c 48 /dev/urandom | base64 | tr -d '=+/' | head -c 64
```

### Generate API Keys (JWT tokens)

You need to generate two JWT tokens using your JWT_SECRET:

**Anonymous Key (ANON_KEY):**
- Role: `anon`
- Issuer: `supabase`
- No expiration

**Service Role Key (SERVICE_ROLE_KEY):**
- Role: `service_role`
- Issuer: `supabase`
- No expiration

Use the Supabase JWT generator at: https://supabase.com/docs/guides/self-hosting/docker#securing-your-services

Or use this Node.js script:
```javascript
const jwt = require('jsonwebtoken');
const secret = 'YOUR_JWT_SECRET_HERE';

// Anon key
const anonToken = jwt.sign(
  { role: 'anon', iss: 'supabase', iat: Math.floor(Date.now() / 1000) },
  secret,
  { noTimestamp: true }
);

// Service role key
const serviceToken = jwt.sign(
  { role: 'service_role', iss: 'supabase', iat: Math.floor(Date.now() / 1000) },
  secret,
  { noTimestamp: true }
);

console.log('ANON_KEY:', anonToken);
console.log('SERVICE_ROLE_KEY:', serviceToken);
```

### Generate Other Secrets

```bash
# SECRET_KEY_BASE (32 characters)
head -c 24 /dev/urandom | base64 | tr -d '=+/' | head -c 32

# VAULT_ENC_KEY (32 characters)
head -c 24 /dev/urandom | base64 | tr -d '=+/' | head -c 32

# PG_META_CRYPTO_KEY (32 characters)
head -c 24 /dev/urandom | base64 | tr -d '=+/' | head -c 32

# LOGFLARE tokens (any random string)
head -c 16 /dev/urandom | base64 | tr -d '=+/'
head -c 16 /dev/urandom | base64 | tr -d '=+/'
```

## Step 2: Create Encrypted Environment Files

Template files have been created in `hosts/pilaster/files/docker/env/*.template`. Use these as guides.

### 2.1 Create supabase-common.env

```bash
agenix -e hosts/pilaster/files/docker/env/supabase-common.env.age
```

Fill in with your generated secrets (replace CHANGE_ME placeholders):
```bash
JWT_SECRET=your_64_char_random_string
ANON_KEY=your_generated_anon_jwt_token
SERVICE_ROLE_KEY=your_generated_service_role_jwt_token
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=your_strong_password
SECRET_KEY_BASE=your_32_char_random_string
VAULT_ENC_KEY=your_32_char_random_string
SITE_URL=https://supabase.meskill.farm
API_EXTERNAL_URL=https://supabase.meskill.farm
SUPABASE_PUBLIC_URL=https://supabase.meskill.farm
SUPABASE_URL=https://supabase.meskill.farm
POSTGREST_URL=http://rest:3000
IMGPROXY_URL=http://imgproxy:5001
FILE_SIZE_LIMIT=52428800
UPLOAD_FILE_SIZE_LIMIT=52428800
JWT_EXPIRY=3600
GOTRUE_JWT_EXP=3600

# Email Configuration (OPTIONAL)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=smtp_user@example.com
SMTP_PASS=smtp_password
SMTP_SENDER_NAME=Supabase
SMTP_ADMIN_EMAIL=admin@example.com

# Auth Configuration
ENABLE_EMAIL_SIGNUP=true
ENABLE_EMAIL_AUTOCONFIRM=false
ENABLE_PHONE_SIGNUP=false
ENABLE_PHONE_AUTOCONFIRM=false
GOTRUE_DISABLE_SIGNUP=false
```

### 2.2 Create supabase-db.env

```bash
agenix -e hosts/pilaster/files/docker/env/supabase-db.env.age
```

**IMPORTANT:** This configures the dedicated Supabase PostgreSQL container (`supabase-db`).

```bash
# PostgreSQL configuration for supabase-db container
POSTGRES_PORT=5432
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_strong_supabase_postgres_password

# Database connection settings (all services use supabase-db hostname)
DB_HOST=supabase-db
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your_strong_supabase_postgres_password

DATABASE_URL=postgresql://postgres:your_strong_supabase_postgres_password@supabase-db:5432/postgres
PGRST_DB_URI=postgresql://postgres:your_strong_supabase_postgres_password@supabase-db:5432/postgres
GOTRUE_DB_DATABASE_URL=postgresql://postgres:your_strong_supabase_postgres_password@supabase-db:5432/postgres
SUPABASE_DB_URL=postgresql://postgres:your_strong_supabase_postgres_password@supabase-db:5432/postgres

PGRST_DB_SCHEMAS=public,storage,graphql_public
PGRST_DB_ANON_ROLE=anon
PGRST_DB_USE_LEGACY_GUCS=false
PGRST_APP_SETTINGS_JWT_SECRET=your_jwt_secret_from_above
PGRST_JWT_SECRET=your_jwt_secret_from_above
API_JWT_SECRET=your_jwt_secret_from_above

PG_META_CRYPTO_KEY=your_32_char_random_string
PG_META_PORT=8080
PG_META_DB_HOST=supabase-db
PG_META_DB_PORT=5432
PG_META_DB_NAME=postgres
PG_META_DB_USER=postgres
PG_META_DB_PASSWORD=your_strong_supabase_postgres_password

# JWT settings (must match supabase-common.env)
JWT_SECRET=your_jwt_secret_from_above
JWT_EXP=3600
```

### 2.3 Create supabase-analytics.env

```bash
agenix -e hosts/pilaster/files/docker/env/supabase-analytics.env.age
```

```bash
LOGFLARE_PUBLIC_ACCESS_TOKEN=your_generated_public_token
LOGFLARE_PRIVATE_ACCESS_TOKEN=your_generated_private_token

DB_USERNAME=postgres
DB_PASSWORD=your_strong_supabase_postgres_password
DB_DATABASE=postgres
DB_HOSTNAME=supabase-db
DB_PORT=5432

POSTGRES_BACKEND_URL=postgresql://postgres:your_strong_supabase_postgres_password@supabase-db:5432/postgres
LOGFLARE_API_KEY=your_service_role_key_from_above

PHOENIX_ENV=production
SINGLE_TENANT=true
LOGFLARE_NODE_HOST=analytics
LOGFLARE_SUPABASE_MODE=true
```

### 2.4 Create supabase-pooler.env

```bash
agenix -e hosts/pilaster/files/docker/env/supabase-pooler.env.age
```

```bash
POOLER_TENANT_ID=prod-pilaster
DATABASE_HOST=supabase-db
DATABASE_PORT=5432
DATABASE_NAME=postgres
DATABASE_USER=postgres
DATABASE_PASSWORD=your_strong_supabase_postgres_password

POOLER_DEFAULT_POOL_SIZE=20
POOLER_MAX_CLIENT_CONN=100
POOLER_DB_POOL_SIZE=5

DATABASE_URL=postgresql://postgres:your_strong_supabase_postgres_password@supabase-db:5432/postgres
SECRET_KEY_BASE=your_secret_key_base_from_above
VAULT_ENC_KEY=your_vault_enc_key_from_above

POOLER_POOL_MODE=transaction
POOLER_PORT=5432
POOLER_PROXY_PORT_TRANSACTION=6543

REGION=local
FLY_APP_NAME=supabase-pooler
```

## Step 3: Update Caddy Configuration

Edit your encrypted Caddyfile to add the Supabase route:

```bash
agenix -e hosts/pilaster/files/caddy/Caddyfile.age
```

Add this block:

```caddyfile
supabase.meskill.farm {
    reverse_proxy supabase-kong:8000

    # Enable request buffering for large requests
    request_body {
        max_size 50MB
    }

    # TLS configuration
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }

    # Logging
    log {
        output file /data/logs/supabase.log
        format json
    }
}
```

## Step 4: Rekey Secrets

After creating all the encrypted files, rekey them for the pilaster host:

```bash
agenix-rekey edit
# or
agenix-rekey rekey
```

## Step 5: Build and Deploy

### 5.1 Commit Configuration Changes

```bash
git add hosts/pilaster/
git commit -m "feat(pilaster): add Supabase full stack deployment

Add complete Supabase setup with 12 services:
- Studio, Kong, Auth, REST, Realtime, Storage
- ImgProxy, Meta, Functions, Analytics, Vector, Pooler

Configuration:
- Using existing postgres:18 with Supabase extensions
- All services on servicenet/datanet networks
- Reverse proxy via Caddy on supabase.meskill.farm
- Volume directories managed by systemd
- Encrypted environment files with agenix

Files added:
- Container definitions in containers.nix
- Kong routing configuration
- Vector logging configuration
- PostgreSQL initialization scripts
- Environment file templates
- Setup documentation
"
```

### 5.2 Deploy to Pilaster

If deploying remotely:
```bash
nixos-rebuild switch --flake .#pilaster --target-host pilaster --use-remote-sudo
```

If deploying locally on pilaster:
```bash
sudo nixos-rebuild switch --flake .#pilaster
```

## Step 6: Initialize Supabase

### 6.1 Verify Services Are Running

```bash
docker ps | grep supabase
```

You should see all 13 Supabase containers running (including supabase-db).

### 6.2 Check Logs

```bash
# Check individual service logs
docker logs supabase-auth
docker logs supabase-rest
docker logs supabase-analytics

# Check supabase-db logs for initialization
docker logs supabase-db
```

### 6.3 Access Supabase Studio

1. Navigate to `https://supabase.meskill.farm`
2. Login with your DASHBOARD_USERNAME and DASHBOARD_PASSWORD
3. The first login will complete initialization

## Step 7: Verify Installation

### Test the API

```bash
# Test anonymous access
curl https://supabase.meskill.farm/rest/v1/ \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_ANON_KEY"

# Test service role access
curl https://supabase.meskill.farm/rest/v1/ \
  -H "apikey: YOUR_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

### Check Studio Dashboard

- **Database**: Should show postgres connection
- **Authentication**: Should show auth configuration
- **Storage**: Should be ready for bucket creation
- **Edge Functions**: Should be ready for function deployment

## Architecture

### Networks

- **proxynet**: Caddy ↔ Kong (port 8000)
- **servicenet**: Internal service communication
- **datanet**: Database access (internal only)

### Services Flow

```
Internet → Caddy (443) → Kong (8000) → [Auth|REST|Storage|Functions|...]
                                       ↓
                                    supabase-db (5432)
```

### Volumes

Supabase data is stored in:
- `/data/docker/supabase-db/pgdata` - PostgreSQL data (dedicated Supabase database)
- `/data/docker/supabase/storage/` - Uploaded files
- `/data/docker/supabase/functions/` - Edge function code

## Troubleshooting

### Container Won't Start

Check dependencies:
```bash
docker logs <container-name>
```

Common issues:
- Database not ready: Wait for postgres to complete initialization
- Missing secrets: Verify all environment variables are set
- Network issues: Ensure docker networks are created

### Database Connection Errors

1. Verify supabase-db password matches in all env files
2. Check supabase-db is on datanet network
3. Verify supabase-db initialization completed:
   ```bash
   docker exec supabase-db psql -U postgres -c "\dn"
   # Should show: _supabase, _analytics, auth, storage, graphql_public, realtime, extensions
   ```

### Kong 404 Errors

1. Verify kong.yml is mounted correctly
2. Check kong logs for configuration errors:
   ```bash
   docker logs supabase-kong
   ```

### Authentication Issues

1. Verify JWT_SECRET matches across all services
2. Check ANON_KEY and SERVICE_ROLE_KEY are valid JWT tokens
3. Verify auth service is running and accessible

### Storage Upload Failures

1. Check `/data/docker/supabase/storage` permissions
2. Verify FILE_SIZE_LIMIT is set appropriately
3. Check imgproxy is running

## Maintenance

### Backup

PostgreSQL data is in `/data/docker/supabase-db/pgdata`
- Back up the dedicated Supabase database separately from the main postgres container
- Use `docker exec supabase-db pg_dump -U postgres postgres > backup.sql`

Storage files in `/data/docker/supabase/storage`
- Include in regular backup routine

### Updates

Update container images in `hosts/pilaster/containers.nix`:
```nix
supabase-studio = {
  image = "supabase/studio:latest";  # Update version
  # ...
};
```

Then rebuild:
```bash
nixos-rebuild switch --flake .#pilaster
```

### Logs

View aggregated logs:
```bash
# All Supabase containers
docker ps --filter "name=supabase-" --format "table {{.Names}}\t{{.Status}}"

# Specific service
docker logs -f supabase-auth

# Analytics/Logflare dashboard
curl https://supabase.meskill.farm/analytics/v1/
```

## References

- [Supabase Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting)
- [Supabase Docker Compose](https://github.com/supabase/supabase/tree/master/docker)
- [Kong Configuration](https://docs.konghq.com/gateway/latest/)
- [PostgREST Documentation](https://postgrest.org/)
- [GoTrue Authentication](https://github.com/supabase/gotrue)
