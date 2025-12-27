# New Services Deployment Plan

**Created:** 2025-12-26
**Status:** Planning
**Last Updated:** 2025-12-26

This document outlines the deployment plan for five new services across the nix-config infrastructure.

## User Requirements (Confirmed)

- **meskill.family domain:** Already registered in Cloudflare
- **Email infrastructure:** No port 25 access, no static IP - will use Cloudflare tunnel + Mailgun relay
- **Gatus alerting:** Discord webhook + email notifications
- **Rallly access:** Public registration allowed

## Overview

| Service | Domain | Host | Priority | Complexity |
|---------|--------|------|----------|------------|
| LinkStack | links.ruinous.social | pilaster | High | Low |
| Gatus | uptime.meskill.farm | monolith | High | Medium |
| Homebox | homebox.meskill.farm | pilaster | Medium | Low |
| Stalwart | mail.meskill.network | monolith | Low | High |
| Rallly | poll.meskill.family | pilaster | Medium | Medium |
| Filestash | files.meskill.farm | pilaster | Medium | Low |
| Homarr | homarr.meskill.farm | pilaster | Medium | Low |
| Supabase | supabase.meskill.farm | pilaster | High | Very High |

## Host Selection Rationale

### pilaster (6 services, including Supabase with 13 containers)
- Already has Cloudflare tunnels configured for ruinous.social domain
- Good capacity with current 35+ containers on i9-13900H with 96GB RAM
- Ideal for web-facing services that need external access
- Supabase adds 13 additional containers but pilaster has capacity

### monolith (2 services)
- Already runs Prometheus + Grafana monitoring stack
- Better for services requiring direct port access (email)
- 60+ containers but well-suited for infrastructure services

---

## 1. LinkStack

**URL:** https://links.ruinous.social
**Host:** pilaster
**Docker Image:** `linkstackorg/linkstack:latest`
**Purpose:** Link aggregation page (like Linktree)

### Requirements

| Resource | Value |
|----------|-------|
| Port | 80/443 (internal), behind Caddy |
| Database | SQLite (embedded) or MariaDB (optional) |
| Storage | `/htdocs` volume for persistent data |
| Memory | ~50-100MB |

### Environment Variables

```env
# Required
TZ=America/Denver
SERVER_ADMIN=admin@ruinous.social
HTTP_SERVER_NAME=links.ruinous.social
HTTPS_SERVER_NAME=links.ruinous.social

# Optional
LOG_LEVEL=info
PHP_MEMORY_LIMIT=256M
UPLOAD_MAX_FILESIZE=8M
```

### Network Configuration

- Network: `servicenet` (accessible via Caddy)
- No direct port exposure needed

### Implementation Steps

- [ ] Create directory: `hosts/pilaster/files/docker/env/`
- [ ] Create `linkstack.env.template` with above variables
- [ ] Encrypt to `linkstack.env.age` after user fills values
- [ ] Add container to `hosts/pilaster/containers.nix`
- [ ] Create data directory on pilaster: `/data/docker/linkstack/`
- [ ] Update Caddyfile with both internal and external domains
- [ ] Create Cloudflare tunnel for `links.ruinous.social`
- [ ] Add DNS entries:
  - `links-int.ruinous.social` CNAME → pilaster.meskill.farm
  - `links.ruinous.social` CNAME (proxied) → tunnel UUID

### Container Definition

```nix
virtualisation.oci-containers.containers.linkstack = {
  image = "linkstackorg/linkstack:latest";
  environmentFiles = [config.age.secrets.pilaster_docker_env_linkstack.path];
  networks = ["servicenet"];
  volumes = [
    "/data/docker/linkstack/htdocs:/htdocs"
  ];
};
```

---

## 2. Gatus

**URL:** https://uptime.meskill.farm
**Host:** monolith
**Docker Image:** `twinproduction/gatus:latest`
**Purpose:** Uptime monitoring and status page for all services

### Requirements

| Resource | Value |
|----------|-------|
| Port | 8080 (internal) |
| Database | SQLite or PostgreSQL (optional for persistence) |
| Storage | `/config` for configuration, `/data` for SQLite |
| Memory | ~50-100MB |

### Configuration File

Gatus uses a YAML configuration file. This needs to be created and mounted.

Create `hosts/monolith/files/docker/gatus/config.yaml`:

```yaml
storage:
  type: sqlite
  path: /data/gatus.db

ui:
  title: "Meskill Farm Status"
  header: "Service Status"

endpoints:
  # === meskill.farm Services (monolith) ===
  - name: "Grafana"
    group: "Monitoring"
    url: "https://grafana.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"
      - "[RESPONSE_TIME] < 2000"

  - name: "Prometheus"
    group: "Monitoring"
    url: "https://prometheus.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "Paperless"
    group: "Productivity"
    url: "https://paperless.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "Forgejo"
    group: "Development"
    url: "https://git.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "n8n"
    group: "Automation"
    url: "https://n8h.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  # === meskill.farm Services (pilaster) ===
  - name: "WikiJS"
    group: "Documentation"
    url: "https://wiki.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "Authentik"
    group: "Security"
    url: "https://auth.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "Archive Box"
    group: "Archiving"
    url: "https://archive.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "Twenty CRM"
    group: "Productivity"
    url: "https://twenty.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "Monica CRM"
    group: "Productivity"
    url: "https://monica.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  # === ruinous.social Services ===
  - name: "Mastodon"
    group: "Social"
    url: "https://ruinous.social"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "Matrix"
    group: "Communication"
    url: "https://matrix.ruinous.social/_matrix/client/versions"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "WriteFreely"
    group: "Social"
    url: "https://blog.ruinous.social"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "Mealie"
    group: "Home"
    url: "https://meals.ruinous.social"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "Karakeep"
    group: "Productivity"
    url: "https://keep.ruinous.social"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "Baikal"
    group: "Productivity"
    url: "https://dav.ruinous.social"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  # === AI Services ===
  - name: "Open WebUI (Zenith)"
    group: "AI"
    url: "https://ai.x.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  - name: "Open WebUI (Obelisk)"
    group: "AI"
    url: "https://ai.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"

  # === Infrastructure ===
  - name: "MCP Gateway"
    group: "Infrastructure"
    url: "https://mcp.meskill.farm"
    interval: 5m
    conditions:
      - "[STATUS] == 200"
```

### Environment Variables

```env
TZ=America/Denver
GATUS_LOG_LEVEL=INFO

# Discord webhook for alerts
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN

# Email alerting (via Mailgun or existing SMTP)
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USERNAME=your-mailgun-username
SMTP_PASSWORD=your-mailgun-password
ALERT_EMAIL_FROM=alerts@meskill.farm
ALERT_EMAIL_TO=admin@meskill.farm
```

### Alerting Configuration

Add to `config.yaml`:

```yaml
alerting:
  discord:
    webhook-url: "${DISCORD_WEBHOOK_URL}"
    default-alert:
      enabled: true
      failure-threshold: 3
      success-threshold: 2
      send-on-resolved: true
      description: "Health check failed"

  email:
    from: "${ALERT_EMAIL_FROM}"
    host: "${SMTP_HOST}"
    port: ${SMTP_PORT}
    username: "${SMTP_USERNAME}"
    password: "${SMTP_PASSWORD}"
    to: "${ALERT_EMAIL_TO}"
    default-alert:
      enabled: true
      failure-threshold: 5
      success-threshold: 2
      send-on-resolved: true
      description: "Health check failed"
```

Then add `alerts` to each endpoint:

```yaml
endpoints:
  - name: "Mastodon"
    group: "Social"
    url: "https://ruinous.social"
    interval: 5m
    conditions:
      - "[STATUS] == 200"
    alerts:
      - type: discord
      - type: email
```

### Network Configuration

- Network: `servicenet` (accessible via Caddy)
- No direct port exposure needed

### Implementation Steps

- [ ] Create directory: `hosts/monolith/files/docker/gatus/`
- [ ] Create `config.yaml` with endpoint monitoring and alerting
- [ ] Create `gatus.env.template` with Discord webhook and SMTP credentials
- [ ] User fills in Discord webhook URL and SMTP credentials
- [ ] Encrypt to `gatus.env.age`
- [ ] Add container to `hosts/monolith/containers.nix`
- [ ] Create data directory: `/data/docker/gatus/`
- [ ] Update Caddyfile on monolith
- [ ] Add DNS entry: `uptime.meskill.farm` CNAME → monolith.meskill.farm

### Container Definition

```nix
virtualisation.oci-containers.containers.gatus = {
  image = "twinproduction/gatus:latest";
  environmentFiles = [config.age.secrets.monolith_docker_env_gatus.path];
  networks = ["servicenet"];
  volumes = [
    "/data/docker/gatus/config:/config:ro"
    "/data/docker/gatus/data:/data"
  ];
};
```

### Future Enhancements

- [ ] Add more detailed health checks (database connectivity, etc.)
- [ ] Integrate with Prometheus for metrics
- [ ] Add PagerDuty integration for critical services

---

## 3. Homebox

**URL:** https://homebox.meskill.farm
**Host:** pilaster
**Docker Image:** `ghcr.io/sysadminsmedia/homebox:latest`
**Purpose:** Home inventory and asset management

### Requirements

| Resource | Value |
|----------|-------|
| Port | 7745 (internal) |
| Database | SQLite (embedded) |
| Storage | `/data` volume for database and uploads |
| Memory | ~50MB idle |

### Environment Variables

```env
TZ=America/Denver
HBOX_LOG_LEVEL=info
HBOX_LOG_FORMAT=text
HBOX_WEB_MAX_UPLOAD_SIZE=10
HBOX_OPTIONS_ALLOW_REGISTRATION=false
HBOX_OPTIONS_ALLOW_ANALYTICS=false
```

### Network Configuration

- Network: `servicenet` (accessible via Caddy)
- No direct port exposure needed

### Implementation Steps

- [x] ~~Create `homebox.env.template`~~ (not needed - used inline environment)
- [x] ~~Encrypt to `homebox.env.age`~~ (not needed - no secrets)
- [x] Add container to `hosts/pilaster/containers.nix`
- [x] Create data directory: `/data/docker/homebox/`
- [x] Update Caddyfile on pilaster
- [x] Add DNS entry: `homebox.meskill.farm` CNAME → pilaster.meskill.farm

### Container Definition

```nix
virtualisation.oci-containers.containers.homebox = {
  image = "ghcr.io/sysadminsmedia/homebox:latest";
  environmentFiles = [config.age.secrets.pilaster_docker_env_homebox.path];
  networks = ["servicenet"];
  volumes = [
    "/data/docker/homebox/data:/data"
  ];
};
```

---

## 4. Stalwart Mail Server

**URL:** https://mail.meskill.network (admin/webmail)
**Host:** monolith
**Docker Image:** `stalwartlabs/stalwart:latest`
**Purpose:** Self-hosted email server with Cloudflare Email Routing + Mailgun relay

### Architecture Overview

Since port 25 is blocked and there's no static IP, we'll use a hybrid approach:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        INBOUND EMAIL FLOW                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Internet → MX (Cloudflare) → Email Routing → Stalwart (via tunnel) │
│                                                                     │
│  OR                                                                 │
│                                                                     │
│  Internet → MX (Mailgun) → Mailgun Inbound → Stalwart webhook       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                       OUTBOUND EMAIL FLOW                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Stalwart → Mailgun SMTP Relay → Internet                           │
│  (Mailgun handles SPF/DKIM/reputation)                              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENT ACCESS                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Mail Client → Cloudflare Tunnel → Stalwart IMAP/SMTP               │
│  (TLS termination at Cloudflare, re-encrypted to origin)            │
│                                                                     │
│  OR (Local/Tailscale access)                                        │
│                                                                     │
│  Mail Client → Caddy → Stalwart IMAP/SMTP                           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Requirements

| Resource | Value |
|----------|-------|
| Ports | Internal only (993, 465, 443) - no public exposure |
| Database | RocksDB (embedded) or PostgreSQL |
| Storage | `/opt/stalwart-mail` for all data |
| Memory | ~200-500MB |
| External | Mailgun account, Cloudflare Email Routing |

### Cloudflare Tunnel Configuration

Create a tunnel for mail services with multiple services:

| Public Hostname | Service | Protocol |
|-----------------|---------|----------|
| mail.meskill.network | stalwart:443 | HTTPS (webmail/admin) |
| imap.meskill.network | stalwart:993 | TCP (IMAPS) |
| smtp.meskill.network | stalwart:465 | TCP (SMTPS submission) |

**Note:** Cloudflare Tunnels support arbitrary TCP, not just HTTP. Configure in `cloudflared.nix`:

```nix
services.cloudflared.tunnels."<tunnel-id>".ingress = {
  "mail.meskill.network" = "https://stalwart:443";
  # TCP services require Cloudflare Spectrum or WARP client
  # For IMAP/SMTP, users will need Cloudflare WARP or Tailscale
};
```

### Alternative: Tailscale for Mail Clients

For simpler client access, use Tailscale:
- Users connect via Tailscale VPN
- Access Stalwart directly at internal IP
- No Cloudflare tunnel needed for IMAP/SMTP
- Only expose webmail via tunnel

### Mailgun Configuration

**Outbound Relay:**
1. Add `meskill.network` domain to Mailgun
2. Configure DNS verification records
3. Get SMTP credentials for relay

**Inbound Routing (Option A - Mailgun Routes):**
1. Set MX records to Mailgun
2. Create inbound route to forward to Stalwart webhook
3. Stalwart receives via HTTP API

**Inbound Routing (Option B - Cloudflare Email Routing):**
1. Enable Email Routing in Cloudflare dashboard
2. Create routing rules to forward to Stalwart
3. Requires Stalwart to accept forwarded mail

### Environment Variables

```env
TZ=America/Denver

# Stalwart basics
STALWART_HOSTNAME=mail.meskill.network
STALWART_DOMAINS=meskill.network

# Mailgun SMTP relay (outbound)
MAILGUN_SMTP_HOST=smtp.mailgun.org
MAILGUN_SMTP_PORT=587
MAILGUN_SMTP_USER=postmaster@meskill.network
MAILGUN_SMTP_PASSWORD=your-mailgun-smtp-password

# Admin password (set on first run or here)
# STALWART_ADMIN_PASSWORD=your-secure-password
```

### Network Configuration

- Network: `servicenet` (internal access via Caddy/tunnel)
- No direct port exposure to internet
- Tailscale recommended for IMAP/SMTP client access

### Implementation Steps

**Phase 1: Mailgun Setup**
- [ ] Add meskill.network domain to Mailgun
- [ ] Configure Mailgun DNS verification (SPF, DKIM via Mailgun)
- [ ] Get SMTP relay credentials
- [ ] Test sending via Mailgun API/SMTP

**Phase 2: Stalwart Container**
- [ ] Create data directory: `/data/docker/stalwart/`
- [ ] Create `stalwart.env.template`
- [ ] User fills in Mailgun credentials
- [ ] Encrypt to `stalwart.env.age`
- [ ] Add container to `hosts/monolith/containers.nix`
- [ ] Configure Stalwart to use Mailgun as relay transport

**Phase 3: Cloudflare Tunnel (Webmail)**
- [ ] Create tunnel for `mail.meskill.network`
- [ ] Add DNS CNAME (proxied) → tunnel
- [ ] Test webmail access

**Phase 4: Client Access**
- [ ] Document Tailscale setup for IMAP/SMTP
- [ ] OR: Set up Cloudflare WARP for TCP tunnel access
- [ ] Test mail client connectivity

**Phase 5: Inbound Mail**
- [ ] Choose: Mailgun Routes OR Cloudflare Email Routing
- [ ] Configure MX records accordingly
- [ ] Set up forwarding to Stalwart
- [ ] Test receiving external mail

**Phase 6: DNS (via Mailgun)**
- [ ] SPF: Mailgun provides this
- [ ] DKIM: Mailgun provides this
- [ ] DMARC: `v=DMARC1; p=quarantine; rua=mailto:dmarc@meskill.network`
- [ ] MX: Point to Mailgun (for inbound routing)

### Container Definition

```nix
virtualisation.oci-containers.containers.stalwart = {
  image = "stalwartlabs/stalwart:latest";
  environmentFiles = [config.age.secrets.monolith_docker_env_stalwart.path];
  networks = ["servicenet"];
  volumes = [
    "/data/docker/stalwart:/opt/stalwart-mail"
  ];
  # No ports exposed - access via Caddy/tunnel/Tailscale
};
```

### Stalwart Relay Configuration

After container starts, configure Stalwart to use Mailgun as relay. In Stalwart admin or config:

```toml
[queue.outbound]
transport = "relay"

[transport.relay]
host = "smtp.mailgun.org"
port = 587
auth.username = "postmaster@meskill.network"
auth.password = "${MAILGUN_SMTP_PASSWORD}"
tls.enable = true
tls.require = true
```

### Complexity Notes

This is the most complex service in the plan. Consider:

1. **Start with outbound only** - Get sending working via Mailgun first
2. **Add webmail** - Test admin interface and webmail via tunnel
3. **Add IMAP** - Client access via Tailscale
4. **Add inbound last** - Most complex, requires MX changes

### Recommended Phased Rollout

| Phase | Capability | Complexity |
|-------|------------|------------|
| 1 | Outbound via Mailgun relay | Low |
| 2 | Webmail via Cloudflare tunnel | Medium |
| 3 | IMAP/SMTP via Tailscale | Medium |
| 4 | Inbound via Mailgun routes | High |

---

## 5. Rallly

**URL:** https://poll.meskill.family
**Host:** pilaster
**Docker Image:** `lukevella/rallly:3`
**Purpose:** Scheduling polls and event coordination

### Requirements

| Resource | Value |
|----------|-------|
| Port | 3000 (internal) |
| Database | PostgreSQL (required) |
| Storage | Stateless (uses database) |
| Memory | ~100-200MB |

### Database Setup

Rallly requires PostgreSQL. Use the existing PostgreSQL 18 on pilaster.

Create database:
```sql
CREATE DATABASE rallly;
CREATE USER rallly WITH PASSWORD 'secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE rallly TO rallly;
```

### Environment Variables

```env
# Required
SECRET_PASSWORD=<generate with: openssl rand -base64 32>
DATABASE_URL=postgres://rallly:PASSWORD@postgres:5432/rallly
NEXT_PUBLIC_BASE_URL=https://poll.meskill.family

# Optional - Email (for notifications)
SMTP_HOST=
SMTP_PORT=587
SMTP_SECURE=true
SMTP_USER=
SMTP_PWD=
SUPPORT_EMAIL=

# Access control (public registration enabled)
AUTH_REQUIRED=false

# Timezone
TZ=America/Denver
```

### Network Configuration

- Networks: `servicenet` + `datanet` (needs database access)
- No direct port exposure needed

### New Domain Setup: meskill.family

This is a NEW domain that needs to be configured:

- [ ] Verify domain ownership in Cloudflare
- [ ] Add domain to cfcli configuration
- [ ] Create initial DNS records

### Implementation Steps

- [x] Set up meskill.family domain in Cloudflare
- [x] Create PostgreSQL database and user
- [x] ~~Create `rallly.env.template`~~ (created directly as encrypted file)
- [x] Encrypt to `rallly.env.age`
- [x] Add container to `hosts/pilaster/containers.nix`
- [x] Update Caddyfile on pilaster
- [x] Add DNS entry: `poll.meskill.family` CNAME → pilaster.meskill.farm
- [x] Add Gatus monitoring entry

### Container Definition

```nix
virtualisation.oci-containers.containers.rallly = {
  image = "lukevella/rallly:3";
  environmentFiles = [config.age.secrets.pilaster_docker_env_rallly.path];
  networks = ["servicenet" "datanet"];
  dependsOn = ["postgres"];
};
```

---

## 6. Filestash

**URL:** https://files.meskill.farm
**Host:** pilaster
**Docker Image:** `machines/filestash:latest`
**Purpose:** Web-based file manager with multi-backend support (SFTP, S3, WebDAV, FTP, etc.)

### Requirements

| Resource | Value |
|----------|-------|
| Port | 8334 (internal) |
| Database | None (embedded state) |
| Storage | `/app/data/state/` for configuration and state |
| Memory | ~128MB minimum |

### Features

- **Multi-backend support:** FTP, SFTP, WebDAV, Git, S3, Minio, Dropbox, Google Drive
- **Authentication:** LDAP, SAML, OpenID, htpasswd
- **File operations:** Browse, upload, download, rename, delete
- **Optional:** Collabora/OnlyOffice integration for document editing (WOPI)

### Environment Variables

```env
# Required
TZ=America/Phoenix

# Optional - set during initial web setup
# APPLICATION_URL=https://files.meskill.farm
```

**Note:** Most configuration is done through the web admin interface at first launch. The admin password is set during initial setup.

### Network Configuration

- Network: `servicenet` (accessible via Caddy)
- No direct port exposure needed

### Implementation Steps

- [ ] Add container to `hosts/pilaster/containers.nix`
- [ ] Create data directory on pilaster: `/data/docker/filestash/`
- [ ] Update Caddyfile on pilaster
- [ ] Add DNS entry: `files.meskill.farm` CNAME → pilaster.meskill.farm
- [ ] Deploy and complete initial setup via web UI
- [ ] Configure storage backends as needed

### Container Definition

```nix
virtualisation.oci-containers.containers.filestash = {
  # IMAGECHECK: disabled - no semver tags available
  image = "machines/filestash:latest";
  environment = {
    TZ = "America/Phoenix";
  };
  networks = ["servicenet"];
  volumes = [
    "/data/docker/filestash/state:/app/data/state"
  ];
};
```

### Optional: Collabora Integration

For document editing capabilities, add Collabora Code as a companion service:

```nix
virtualisation.oci-containers.containers.filestash-collabora = {
  image = "collabora/code:24.04.10.2.1";
  environment = {
    extra_params = "--o:ssl.enable=false";
  };
  networks = ["servicenet"];
};
```

Then configure Filestash to use `http://filestash-collabora:9980` as the WOPI server.

### Post-Installation Configuration

1. Access `https://files.meskill.farm` after deployment
2. Set admin password during initial setup
3. Configure storage backends:
   - **Local files:** Mount additional volumes if needed
   - **SFTP:** Connect to other hosts (e.g., terranas)
   - **S3:** Connect to MinIO or AWS S3
   - **WebDAV:** Connect to Nextcloud or other WebDAV servers
4. Configure authentication if needed (LDAP via Authentik)

---

## 7. Homarr

**URL:** https://homarr.meskill.farm
**Host:** pilaster
**Docker Image:** `ghcr.io/homarr-labs/homarr:latest`
**Purpose:** Modern dashboard for managing and monitoring home server services

### Requirements

| Resource | Value |
|----------|-------|
| Port | 7575 (internal) |
| Database | SQLite (embedded) |
| Storage | `/appdata` for configuration and icons |
| Memory | ~100-200MB |

### Features

- **Service dashboard:** Organize and access all your services in one place
- **Widget support:** Weather, calendar, RSS feeds, system stats, and more
- **Service integration:** Native integrations with *arr apps, Plex, Jellyfin, etc.
- **Docker integration:** View and manage Docker containers
- **Customizable:** Themes, layouts, and custom CSS support
- **Authentication:** Built-in auth or OIDC/LDAP integration

### Environment Variables

```env
# Required
TZ=America/Phoenix

# Optional - defaults work well
# SECRET_ENCRYPTION_KEY=<generate with: openssl rand -hex 32>
```

**Note:** Most configuration is done through the web UI. The encryption key is auto-generated if not provided.

### Network Configuration

- Network: `servicenet` (accessible via Caddy)
- No direct port exposure needed

### Implementation Steps

- [ ] Add container to `hosts/pilaster/containers.nix`
- [ ] Create data directory on pilaster: `/data/docker/homarr/`
- [ ] Update Caddyfile on pilaster
- [ ] Add DNS entry: `homarr.meskill.farm` CNAME → pilaster.meskill.farm
- [ ] Deploy and configure dashboard via web UI
- [ ] Add service widgets and integrations
- [ ] Add to Gatus monitoring

### Container Definition

```nix
virtualisation.oci-containers.containers.homarr = {
  image = "ghcr.io/homarr-labs/homarr:latest";
  environment = {
    TZ = "America/Phoenix";
  };
  networks = ["servicenet"];
  volumes = [
    "/data/docker/homarr/appdata:/appdata"
    "/var/run/docker.sock:/var/run/docker.sock:ro"  # Optional: for Docker integration
  ];
};
```

### Post-Installation Configuration

1. Access `https://homarr.meskill.farm` after deployment
2. Create admin account during initial setup
3. Add services to dashboard:
   - Internal services (via internal URLs)
   - External services (via public URLs)
4. Configure widgets:
   - Weather for local area
   - Calendar integration
   - System stats
5. Optional: Configure OIDC via Authentik for SSO

---

## 8. Supabase

**URL:** https://supabase.meskill.farm
**Host:** pilaster
**Purpose:** Self-hosted Backend-as-a-Service (PostgreSQL, Authentication, Storage, Realtime, Edge Functions)

### Previous Attempt Status

A previous deployment attempt was started and includes:
- ✅ Encrypted secrets already created (4 env files)
- ✅ Kong API gateway configuration
- ✅ Vector log routing configuration
- ✅ PostgreSQL configuration
- ✅ Database initialization scripts
- ⚠️ Container definitions exist but are commented out
- ❌ Service hostnames in kong.yml need fixing (use full container names)
- ❌ Service hostnames in vector.yml need verification

### Architecture

Supabase consists of 13 interconnected services:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SUPABASE STACK                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Internet → Caddy (443) → supabase-kong (8000) → Services          │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ API GATEWAY (supabase-kong)                                   │  │
│  │ Routes requests to appropriate services                       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                              ↓                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ CORE SERVICES                                                 │  │
│  │ ├── supabase-auth (GoTrue) - Authentication                  │  │
│  │ ├── supabase-rest (PostgREST) - REST API                     │  │
│  │ ├── supabase-realtime - WebSocket subscriptions              │  │
│  │ ├── supabase-storage - File storage                          │  │
│  │ └── supabase-functions - Edge functions                      │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                              ↓                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ INFRASTRUCTURE                                                │  │
│  │ ├── supabase-db - Dedicated PostgreSQL 15.8                  │  │
│  │ ├── supabase-pooler (Supavisor) - Connection pooling         │  │
│  │ ├── supabase-meta - Database metadata API                    │  │
│  │ ├── supabase-imgproxy - Image transformations                │  │
│  │ ├── supabase-analytics (Logflare) - Logging                  │  │
│  │ └── supabase-vector - Log routing                            │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                              ↓                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ DASHBOARD                                                     │  │
│  │ └── supabase-studio - Web admin interface                    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Service Details

| Service | Image | Port | Networks | Dependencies |
|---------|-------|------|----------|--------------|
| supabase-db | supabase/postgres:15.8.1.085 | 5432 | datanet, servicenet | - |
| supabase-analytics | supabase/logflare:1.22.6 | 4000 | datanet, servicenet | supabase-db |
| supabase-vector | timberio/vector:0.28.1-alpine | - | servicenet | - |
| supabase-auth | supabase/gotrue:v2.182.1 | 9999 | datanet, servicenet | supabase-db, analytics |
| supabase-rest | postgrest/postgrest:v13.0.7 | 3000 | datanet, servicenet | supabase-db, analytics |
| supabase-meta | supabase/postgres-meta:v0.93.1 | 8080 | datanet, servicenet | supabase-db, analytics |
| supabase-kong | kong:2.8.1 | 8000 | proxynet, servicenet | analytics |
| supabase-studio | supabase/studio:2025.11.10 | 3000 | servicenet | supabase-db, analytics |
| supabase-realtime | supabase/realtime:v2.63.0 | 4000 | datanet, servicenet | supabase-db, analytics |
| supabase-storage | supabase/storage-api:v1.29.0 | 5000 | datanet, servicenet | supabase-db, rest, imgproxy |
| supabase-imgproxy | darthsim/imgproxy:v3.8.0 | 5001 | servicenet | - |
| supabase-functions | supabase/edge-runtime:v1.69.23 | 9000 | servicenet | - |
| supabase-pooler | supabase/supavisor:2.7.4 | 5432/6543 | datanet, servicenet | supabase-db, analytics |

### Existing Configuration Files

| File | Purpose | Status |
|------|---------|--------|
| `files/docker/env/supabase-common.env.age` | Shared secrets (JWT, API keys) | ✅ Exists |
| `files/docker/env/supabase-db.env.age` | Database credentials | ✅ Exists |
| `files/docker/env/supabase-analytics.env.age` | Logflare tokens | ✅ Exists |
| `files/docker/env/supabase-pooler.env.age` | Pooler config | ✅ Exists |
| `files/supabase/api/kong.yml` | API gateway routes | ⚠️ Needs hostname fix |
| `files/supabase/logs/vector.yml` | Log routing | ⚠️ Needs hostname fix |
| `files/supabase/postgres/postgresql.conf` | DB config | ✅ Exists |
| `files/supabase/db/*.sql` | Init scripts | ✅ Exists |

### Required Fixes Before Deployment

#### Fix 1: kong.yml Service Hostnames

The kong.yml uses short names like `auth:9999` but containers are named `supabase-auth`. Update all service references:

| Current | Should Be |
|---------|-----------|
| `http://auth:9999` | `http://supabase-auth:9999` |
| `http://rest:3000` | `http://supabase-rest:3000` |
| `http://realtime-dev.supabase-realtime:4000` | `http://supabase-realtime:4000` |
| `http://storage:5000` | `http://supabase-storage:5000` |
| `http://functions:9000` | `http://supabase-functions:9000` |
| `http://analytics:4000` | `http://supabase-analytics:4000` |
| `http://meta:8080` | `http://supabase-meta:8080` |
| `http://studio:3000` | `http://supabase-studio:3000` |
| `http://kong:8000` | `http://supabase-kong:8000` |

#### Fix 2: vector.yml Container Names

Update container name references in router rules and ensure analytics URI uses correct hostname.

#### Fix 3: Realtime DNS_NODES Environment

The realtime container has a complex DNS_NODES setting. Simplify or verify it works with Docker DNS.

### Phased Deployment Approach

Given complexity, deploy in phases to isolate issues:

#### Phase 1: Database Foundation
1. Create data directories on pilaster:
   - `/data/docker/supabase-db/pgdata`
   - `/data/docker/supabase-db/custom`
2. Enable `supabase-db` container (uncomment in containers.nix)
3. Deploy and verify database is healthy
4. Check: `docker logs supabase-db`, health check passes

#### Phase 2: Logging Infrastructure
5. Enable `supabase-analytics` (Logflare)
6. Enable `supabase-vector` (log routing)
7. Deploy and verify logs are flowing
8. Check: `docker logs supabase-analytics`, API responding

#### Phase 3: Core API Services
9. Fix kong.yml hostnames
10. Enable `supabase-auth`
11. Enable `supabase-rest`
12. Enable `supabase-meta`
13. Enable `supabase-kong`
14. Deploy and verify API gateway works
15. Check: Kong health, auth endpoint responds

#### Phase 4: Dashboard & Access
16. Enable `supabase-studio`
17. Update Caddyfile for `supabase.meskill.farm`
18. Create DNS entry
19. Deploy and verify Studio loads
20. Check: Login with dashboard credentials works

#### Phase 5: Additional Services
21. Enable `supabase-realtime`
22. Enable `supabase-storage` + `supabase-imgproxy`
23. Enable `supabase-functions`
24. Enable `supabase-pooler`
25. Final verification of all services

### Environment Variables Summary

**supabase-common.env** (shared):
```env
JWT_SECRET=<64-char random string>
ANON_KEY=<generated JWT token, role=anon>
SERVICE_ROLE_KEY=<generated JWT token, role=service_role>
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=<strong password>
SECRET_KEY_BASE=<32-char random>
VAULT_ENC_KEY=<32-char random>
SITE_URL=https://supabase.meskill.farm
API_EXTERNAL_URL=https://supabase.meskill.farm
```

**supabase-db.env**:
```env
POSTGRES_PASSWORD=<database password>
DATABASE_URL=postgresql://postgres:<password>@supabase-db:5432/postgres
# Plus JWT secrets for PostgREST
```

### Network Configuration

- `proxynet`: supabase-kong (external access via Caddy)
- `servicenet`: All services (internal communication)
- `datanet`: supabase-db, auth, rest, meta, storage, realtime, pooler, analytics

### Volume Mounts

```
/data/docker/supabase-db/pgdata     → Postgres data
/data/docker/supabase-db/custom     → Custom Postgres config
/data/docker/supabase/storage       → Uploaded files
/data/docker/supabase/functions     → Edge function code
```

### Implementation Steps

- [ ] **Phase 1: Database**
  - [ ] Create data directories on pilaster
  - [ ] Uncomment supabase-db in containers.nix
  - [ ] Deploy and verify database health

- [ ] **Phase 2: Logging**
  - [ ] Uncomment supabase-analytics
  - [ ] Uncomment supabase-vector
  - [ ] Deploy and verify logging

- [ ] **Phase 3: Core API**
  - [ ] Fix kong.yml hostnames
  - [ ] Fix vector.yml hostnames
  - [ ] Uncomment supabase-auth, rest, meta, kong
  - [ ] Deploy and verify API

- [ ] **Phase 4: Dashboard**
  - [ ] Uncomment supabase-studio
  - [ ] Update Caddyfile
  - [ ] Create DNS entry: supabase.meskill.farm → pilaster.meskill.farm
  - [ ] Deploy and verify Studio access

- [ ] **Phase 5: Additional Services**
  - [ ] Uncomment supabase-realtime
  - [ ] Uncomment supabase-storage, imgproxy
  - [ ] Uncomment supabase-functions
  - [ ] Uncomment supabase-pooler
  - [ ] Final verification

- [ ] **Phase 6: Monitoring**
  - [ ] Add to Gatus monitoring
  - [ ] Deploy Gatus update

### Troubleshooting Reference

See `hosts/pilaster/SUPABASE_SETUP.md` for detailed troubleshooting including:
- Container startup issues
- Database connection errors
- Kong 404 errors
- Authentication issues
- Storage upload failures

### References

- [Supabase Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting)
- [Supabase Docker Compose](https://github.com/supabase/supabase/tree/master/docker)
- [Kong Configuration](https://docs.konghq.com/gateway/latest/)
- [PostgREST Documentation](https://postgrest.org/)
- [GoTrue Authentication](https://github.com/supabase/gotrue)

---

## Implementation Order

### Phase 1: Quick Wins (Low complexity, high value)
1. **LinkStack** - Simple setup, extends ruinous.social
2. **Homebox** - Simple setup, useful for home inventory
3. **Filestash** - Simple setup, web-based file manager
4. **Homarr** - Simple setup, service dashboard

### Phase 2: Infrastructure (Medium complexity)
5. **Gatus** - Monitoring is important, medium config needed
6. **Rallly** - Requires new domain setup + database

### Phase 3: Complex Services (High complexity)
7. **Stalwart** - Email is complex, requires careful DNS setup
8. **Supabase** - Very complex, 13 containers, phased deployment required

---

## Secrets Summary

### pilaster secrets to create:
- `pilaster_docker_env_linkstack`
- `pilaster_docker_env_homebox`
- `pilaster_docker_env_rallly`
- `pilaster_docker_env_supabase_common` (✅ exists)
- `pilaster_docker_env_supabase_db` (✅ exists)
- `pilaster_docker_env_supabase_analytics` (✅ exists)
- `pilaster_docker_env_supabase_pooler` (✅ exists)

### monolith secrets to create:
- `monolith_docker_env_gatus`
- `monolith_docker_env_stalwart`

---

## DNS Summary

### meskill.farm (existing domain)
| Record | Type | Target |
|--------|------|--------|
| uptime | CNAME | monolith.meskill.farm |
| homebox | CNAME | pilaster.meskill.farm |
| files | CNAME | pilaster.meskill.farm |
| homarr | CNAME | pilaster.meskill.farm |
| supabase | CNAME | pilaster.meskill.farm |

### ruinous.social (existing domain, tunneled)
| Record | Type | Target |
|--------|------|--------|
| links-int | CNAME | pilaster.meskill.farm |
| links | CNAME (proxied) | <tunnel-uuid>.cfargotunnel.com |

### meskill.network (existing domain, email via Mailgun)
| Record | Type | Target |
|--------|------|--------|
| mail | CNAME (proxied) | <tunnel-uuid>.cfargotunnel.com (webmail) |
| mail-int | CNAME | monolith.meskill.farm |
| MX @ | MX | mxa.mailgun.org (priority 10) |
| MX @ | MX | mxb.mailgun.org (priority 10) |
| @ | TXT | v=spf1 include:mailgun.org ~all |
| smtp._domainkey | TXT | (Mailgun provides DKIM key) |
| _dmarc | TXT | v=DMARC1; p=quarantine; rua=mailto:dmarc@meskill.network |

### meskill.family (NEW domain)
| Record | Type | Target |
|--------|------|--------|
| poll | CNAME | pilaster.meskill.farm |

---

## Cloudflare Tunnel Summary

### New tunnels needed on pilaster:
- **links-ruinous** tunnel for `links.ruinous.social`

### New tunnels needed on monolith:
- **mail-meskill** tunnel for `mail.meskill.network` (webmail/admin)

---

## Checklist for Each Service

Use this checklist when implementing each service:

```markdown
### Service: <name>

#### Pre-implementation
- [ ] User confirmed host selection
- [ ] User confirmed domain/URL
- [ ] Required secrets gathered

#### Implementation
- [ ] agenix-helper unlocked
- [ ] Environment template created
- [ ] Environment file encrypted
- [ ] Container added to containers.nix
- [ ] Data directories created on host
- [ ] Secret definition added to containers.nix
- [ ] agenix rekey completed
- [ ] Caddyfile updated (if needed)
- [ ] Cloudflare tunnel created (if needed)
- [ ] DNS entries created
- [ ] agenix-helper locked

#### Verification
- [ ] nixos-rebuild dry-build passes
- [ ] Service accessible at URL
- [ ] Documentation updated
```

---

## References

- [LinkStack Documentation](https://docs.linkstack.org/docker/setup/)
- [LinkStack Docker GitHub](https://github.com/LinkStackOrg/linkstack-docker)
- [Gatus GitHub](https://github.com/TwiN/gatus)
- [Homebox Documentation](https://homebox.software/en/installation)
- [Homebox GitHub](https://github.com/hay-kot/homebox)
- [Stalwart Documentation](https://stalw.art/docs/install/platform/docker/)
- [Stalwart GitHub](https://github.com/stalwartlabs/stalwart)
- [Rallly Self-Hosted](https://github.com/lukevella/rallly-selfhosted)
- [Rallly Documentation](https://support.rallly.co/self-hosting/installation/docker)
- [Filestash Documentation](https://www.filestash.app/docs/install-and-upgrade/)
- [Filestash Docker Hub](https://hub.docker.com/r/machines/filestash/)

---

## Session Notes

Use this section to track progress across sessions:

### Session 1 (2025-12-26)
- Created initial deployment plan
- Researched all service requirements
- Determined host placement
- Documented DNS and secret requirements
- **User confirmed:**
  - meskill.family domain is already in Cloudflare
  - No port 25 access, no static IP → use Cloudflare tunnel + Mailgun relay
  - Gatus alerts via Discord webhook + email
  - Rallly allows public registration
- Updated Stalwart architecture to use Mailgun relay + Cloudflare tunnel
- Updated Gatus with Discord/email alerting configuration

### Session 2 (2025-12-26)
- **User confirmed implementation decisions:**
  - Keep Gatus endpoints as planned (~20 services)
  - Stalwart: Include inbound email from the start (full Mailgun setup)
  - Rallly: Use existing PostgreSQL on pilaster
  - **Start with Gatus implementation**
- **Gatus implementation completed:**
  - Created `hosts/monolith/files/gatus/config.yaml` with 20 endpoints
  - Created and encrypted `hosts/monolith/files/docker/env/gatus.env.age`
  - Added container to `hosts/monolith/containers.nix`
  - Updated monolith Caddyfile
  - Created DNS entry: `uptime.meskill.farm` → `monolith.meskill.farm`
- **Documentation updates:**
  - Updated `CLAUDE.md` with Step 10 for Gatus monitoring in "Adding Docker Containers"
  - Updated `.claude/agents/containnix.md` with Gatus step and remote deployment options

### Next Steps
- [x] User reviews complete plan
- [x] Gather required credentials (Gatus)
- [x] Implement Gatus on monolith
- [x] Deploy Gatus to monolith
- [x] Implement LinkStack on pilaster
- [x] Implement Homebox on pilaster
- [x] Implement Rallly on pilaster
- [x] Implement Filestash on pilaster
- [x] Implement Homarr on pilaster
- [ ] **Implement Supabase on pilaster** (phased deployment - see Section 8)
  - [ ] Phase 1: Database (supabase-db)
  - [ ] Phase 2: Logging (analytics, vector)
  - [ ] Phase 3: Core API (auth, rest, meta, kong)
  - [ ] Phase 4: Dashboard (studio, Caddy, DNS)
  - [ ] Phase 5: Additional services (realtime, storage, functions, pooler)
  - [ ] Phase 6: Gatus monitoring
- [ ] Implement Stalwart on monolith
