# Next Steps: Supabase Deployment

## Overview
The Supabase configuration is complete and committed. Follow these steps to generate secrets and deploy.

## Step 1: Generate Secrets (Local Machine)

### 1.1 Generate JWT Secret
```bash
# Generate 64-character JWT secret
JWT_SECRET=$(head -c 48 /dev/urandom | base64 | tr -d '=+/' | head -c 64)
echo "JWT_SECRET=$JWT_SECRET"
```

### 1.2 Generate API Keys (JWT Tokens)

Create a Node.js script to generate the JWT tokens:

```bash
# Create temporary script
cat > /tmp/generate-jwt.js << 'EOF'
const jwt = require('jsonwebtoken');
const secret = process.argv[2];

if (!secret) {
  console.error('Usage: node generate-jwt.js <JWT_SECRET>');
  process.exit(1);
}

// Anon key
const anonToken = jwt.sign(
  { role: 'anon', iss: 'supabase' },
  secret,
  { expiresIn: '10y' }
);

// Service role key
const serviceToken = jwt.sign(
  { role: 'service_role', iss: 'supabase' },
  secret,
  { expiresIn: '10y' }
);

console.log('ANON_KEY=' + anonToken);
console.log('SERVICE_ROLE_KEY=' + serviceToken);
EOF

# Install jsonwebtoken if needed
npm install -g jsonwebtoken

# Run the script with your JWT_SECRET
node /tmp/generate-jwt.js "$JWT_SECRET"
```

### 1.3 Generate Other Secrets
```bash
# SECRET_KEY_BASE (32 characters)
SECRET_KEY_BASE=$(head -c 24 /dev/urandom | base64 | tr -d '=+/' | head -c 32)
echo "SECRET_KEY_BASE=$SECRET_KEY_BASE"

# VAULT_ENC_KEY (32 characters)
VAULT_ENC_KEY=$(head -c 24 /dev/urandom | base64 | tr -d '=+/' | head -c 32)
echo "VAULT_ENC_KEY=$VAULT_ENC_KEY"

# PG_META_CRYPTO_KEY (32 characters)
PG_META_CRYPTO_KEY=$(head -c 24 /dev/urandom | base64 | tr -d '=+/' | head -c 32)
echo "PG_META_CRYPTO_KEY=$PG_META_CRYPTO_KEY"

# LOGFLARE_PUBLIC_ACCESS_TOKEN
LOGFLARE_PUBLIC_TOKEN=$(head -c 16 /dev/urandom | base64 | tr -d '=+/')
echo "LOGFLARE_PUBLIC_ACCESS_TOKEN=$LOGFLARE_PUBLIC_TOKEN"

# LOGFLARE_PRIVATE_ACCESS_TOKEN
LOGFLARE_PRIVATE_TOKEN=$(head -c 16 /dev/urandom | base64 | tr -d '=+/')
echo "LOGFLARE_PRIVATE_ACCESS_TOKEN=$LOGFLARE_PRIVATE_TOKEN"
```

### 1.4 Save All Secrets
```bash
# Create a temporary file with all secrets (DON'T COMMIT THIS)
cat > /tmp/supabase-secrets.env << EOF
JWT_SECRET=$JWT_SECRET
ANON_KEY=<paste_from_jwt_script>
SERVICE_ROLE_KEY=<paste_from_jwt_script>
SECRET_KEY_BASE=$SECRET_KEY_BASE
VAULT_ENC_KEY=$VAULT_ENC_KEY
PG_META_CRYPTO_KEY=$PG_META_CRYPTO_KEY
LOGFLARE_PUBLIC_ACCESS_TOKEN=$LOGFLARE_PUBLIC_TOKEN
LOGFLARE_PRIVATE_ACCESS_TOKEN=$LOGFLARE_PRIVATE_TOKEN
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=<choose_strong_password>
EOF

# Review the file
cat /tmp/supabase-secrets.env
```

## Step 2: Get Postgres Password

Retrieve the existing postgres password from your encrypted env file:

```bash
# Unlock age identity if needed
agenix-helper unlock

# Decrypt and view postgres password
agenix -d hosts/pilaster/files/docker/env/postgres.env.age | grep POSTGRES_PASSWORD
```

## Step 3: Create Encrypted Environment Files

### 3.1 Create supabase-common.env.age
```bash
agenix -e hosts/pilaster/files/docker/env/supabase-common.env.age
```

Paste this content (replace values):
```bash
# From /tmp/supabase-secrets.env
JWT_SECRET=<your_jwt_secret>
ANON_KEY=<your_anon_key>
SERVICE_ROLE_KEY=<your_service_role_key>
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=<your_dashboard_password>
SECRET_KEY_BASE=<your_secret_key_base>
VAULT_ENC_KEY=<your_vault_enc_key>

# Site Configuration
SITE_URL=https://supabase.meskill.farm
API_EXTERNAL_URL=https://supabase.meskill.farm
SUPABASE_PUBLIC_URL=https://supabase.meskill.farm
SUPABASE_URL=https://supabase.meskill.farm
POSTGREST_URL=http://rest:3000
IMGPROXY_URL=http://imgproxy:5001

# File Upload Limits
FILE_SIZE_LIMIT=52428800
UPLOAD_FILE_SIZE_LIMIT=52428800

# JWT Configuration
JWT_EXPIRY=3600
GOTRUE_JWT_EXP=3600

# Auth Configuration
ENABLE_EMAIL_SIGNUP=true
ENABLE_EMAIL_AUTOCONFIRM=false
ENABLE_PHONE_SIGNUP=false
ENABLE_PHONE_AUTOCONFIRM=false
GOTRUE_DISABLE_SIGNUP=false

# SMTP (Optional - comment out if not using)
# SMTP_HOST=smtp.example.com
# SMTP_PORT=587
# SMTP_USER=smtp_user@example.com
# SMTP_PASS=smtp_password
# SMTP_SENDER_NAME=Supabase
# SMTP_ADMIN_EMAIL=admin@example.com
```

### 3.2 Create supabase-db.env.age
```bash
agenix -e hosts/pilaster/files/docker/env/supabase-db.env.age
```

Paste this content (replace POSTGRES_PASSWORD with actual value):
```bash
# Database Connection
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<your_existing_postgres_password>

DB_HOST=postgres
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=<your_existing_postgres_password>

# Connection Strings
DATABASE_URL=postgresql://postgres:<your_existing_postgres_password>@postgres:5432/postgres
PGRST_DB_URI=postgresql://postgres:<your_existing_postgres_password>@postgres:5432/postgres
GOTRUE_DB_DATABASE_URL=postgresql://postgres:<your_existing_postgres_password>@postgres:5432/postgres
SUPABASE_DB_URL=postgresql://postgres:<your_existing_postgres_password>@postgres:5432/postgres

# PostgREST Configuration
PGRST_DB_SCHEMAS=public,storage,graphql_public
PGRST_DB_ANON_ROLE=anon
PGRST_DB_USE_LEGACY_GUCS=false
PGRST_APP_SETTINGS_JWT_SECRET=<your_jwt_secret>
PGRST_JWT_SECRET=<your_jwt_secret>
API_JWT_SECRET=<your_jwt_secret>

# Postgres Meta
PG_META_CRYPTO_KEY=<your_pg_meta_crypto_key>
PG_META_PORT=8080
PG_META_DB_HOST=postgres
PG_META_DB_PORT=5432
PG_META_DB_NAME=postgres
PG_META_DB_USER=postgres
PG_META_DB_PASSWORD=<your_existing_postgres_password>

PGDATA=/var/lib/postgresql/18/docker
```

### 3.3 Create supabase-analytics.env.age
```bash
agenix -e hosts/pilaster/files/docker/env/supabase-analytics.env.age
```

Paste this content:
```bash
# Logflare Tokens
LOGFLARE_PUBLIC_ACCESS_TOKEN=<your_logflare_public_token>
LOGFLARE_PRIVATE_ACCESS_TOKEN=<your_logflare_private_token>

# Database Connection
DB_USERNAME=postgres
DB_PASSWORD=<your_existing_postgres_password>
DB_DATABASE=postgres
DB_HOSTNAME=postgres
DB_PORT=5432

POSTGRES_BACKEND_URL=postgresql://postgres:<your_existing_postgres_password>@postgres:5432/postgres
LOGFLARE_API_KEY=<your_service_role_key>

# Configuration
PHOENIX_ENV=production
SINGLE_TENANT=true
LOGFLARE_NODE_HOST=analytics
LOGFLARE_SUPABASE_MODE=true
```

### 3.4 Create supabase-pooler.env.age
```bash
agenix -e hosts/pilaster/files/docker/env/supabase-pooler.env.age
```

Paste this content:
```bash
# Pooler Configuration
POOLER_TENANT_ID=prod-pilaster
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=postgres
DATABASE_USER=postgres
DATABASE_PASSWORD=<your_existing_postgres_password>

POOLER_DEFAULT_POOL_SIZE=20
POOLER_MAX_CLIENT_CONN=100
POOLER_DB_POOL_SIZE=5

DATABASE_URL=postgresql://postgres:<your_existing_postgres_password>@postgres:5432/postgres
SECRET_KEY_BASE=<your_secret_key_base>
VAULT_ENC_KEY=<your_vault_enc_key>

POOLER_POOL_MODE=transaction
POOLER_PORT=5432
POOLER_PROXY_PORT_TRANSACTION=6543

REGION=local
FLY_APP_NAME=supabase-pooler
```

## Step 4: Update Caddyfile

```bash
agenix -e hosts/pilaster/files/caddy/Caddyfile.age
```

Add this block to the file:
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

## Step 5: Rekey Secrets

```bash
# Rekey all secrets
agenix-rekey rekey

# Verify rekeyed files exist
ls -la hosts/pilaster/files/docker/env/*.age
ls -la hosts/pilaster/files/caddy/Caddyfile.age
```

## Step 6: Commit Changes

```bash
# Check status
git status

# Add rekeyed secret files
git add hosts/pilaster/files/docker/env/*.age
git add hosts/pilaster/files/caddy/Caddyfile.age

# Commit
git commit -m "feat(pilaster): add encrypted Supabase environment files

Add encrypted environment files for Supabase deployment:
- supabase-common.env.age: JWT secrets, API keys, site config
- supabase-db.env.age: Database connection strings
- supabase-analytics.env.age: Logflare tokens
- supabase-pooler.env.age: Connection pooler config
- Updated Caddyfile with supabase.meskill.farm route

All secrets generated with strong random values.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

## Step 7: Deploy to Pilaster

### 7.1 Dry-run (optional)
```bash
nixos-rebuild dry-build --flake .#pilaster
```

### 7.2 Deploy
```bash
# If deploying remotely
nixos-rebuild switch --flake .#pilaster --target-host pilaster --use-remote-sudo

# OR if on pilaster directly
sudo nixos-rebuild switch --flake .#pilaster
```

## Step 8: Verify Deployment

### 8.1 Check Container Status
```bash
# SSH to pilaster
ssh pilaster

# Check all Supabase containers
docker ps | grep supabase

# Should see 12 containers:
# - supabase-studio
# - supabase-kong
# - supabase-auth
# - supabase-rest
# - supabase-realtime
# - supabase-storage
# - supabase-imgproxy
# - supabase-meta
# - supabase-functions
# - supabase-analytics
# - supabase-vector
# - supabase-pooler
```

### 8.2 Check Logs
```bash
# Check for errors in critical services
docker logs supabase-analytics
docker logs supabase-auth
docker logs supabase-rest
docker logs postgres | grep -i supabase
```

### 8.3 Test Access
```bash
# Test Caddy routing
curl -I https://supabase.meskill.farm

# Should return Kong headers
```

### 8.4 Access Studio Dashboard
1. Open browser to `https://supabase.meskill.farm`
2. Login with DASHBOARD_USERNAME and DASHBOARD_PASSWORD
3. Verify database connection shows postgres
4. Check that all services are accessible

## Step 9: Test API

```bash
# Test anonymous access
curl https://supabase.meskill.farm/rest/v1/ \
  -H "apikey: <YOUR_ANON_KEY>" \
  -H "Authorization: Bearer <YOUR_ANON_KEY>"

# Test service role access
curl https://supabase.meskill.farm/rest/v1/ \
  -H "apikey: <YOUR_SERVICE_ROLE_KEY>" \
  -H "Authorization: Bearer <YOUR_SERVICE_ROLE_KEY>"
```

## Step 10: Cleanup

```bash
# Remove temporary secrets file
rm /tmp/supabase-secrets.env
rm /tmp/generate-jwt.js

# Lock age identity if done
agenix-helper lock
```

## Troubleshooting

If deployment fails, check:

1. **Encrypted files exist:**
   ```bash
   ls -la hosts/pilaster/files/docker/env/supabase-*.age
   ```

2. **Secrets are properly rekeyed:**
   ```bash
   agenix-rekey rekey
   ```

3. **Postgres password matches:**
   Compare password in supabase-db.env.age with postgres.env.age

4. **Container logs for errors:**
   ```bash
   docker logs <container-name>
   ```

5. **Network connectivity:**
   ```bash
   docker network ls
   docker network inspect servicenet
   docker network inspect datanet
   docker network inspect proxynet
   ```

## Reference

- Full setup guide: `hosts/pilaster/SUPABASE_SETUP.md`
- Environment templates: `hosts/pilaster/files/docker/env/*.template`
- Supabase docs: https://supabase.com/docs/guides/self-hosting
