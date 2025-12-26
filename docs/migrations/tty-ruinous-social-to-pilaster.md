# Migration Plan: tty-ruinous-social to pilaster

**Created:** 2025-12-23
**Status:** In Progress - Starting with albyhub

## Overview

Migrate containers from tty-ruinous-social (Linode VPS at tty.ruinous.social) to pilaster (local MS-01 server). All services will be exposed via Cloudflare tunnels.

**Source:** tty.ruinous.social (VPS)
**Target:** pilaster (local, 1.8TB free, 96GB RAM, PostgreSQL 18, Redis 7)
**Data Sources:** Direct SSH or restic backups on local network

## Services to Migrate

| Service | Database | Domains | Complexity | Status |
|---------|----------|---------|------------|--------|
| albyhub | SQLite (local) | alby.ruinous.social | Simple | Config Complete |
| baikal | SQLite (local) | dav.ruinous.social | Simple | Config Complete |
| mealie | SQLite (local) | meals.ruinous.social | Simple | Config Complete |
| writefreely | SQLite (local) | blog.ruinous.social | Simple | Config Complete |
| karakeep (3 containers) | SQLite + Meilisearch | keep/hoarder/karakeep.ruinous.social | Medium | Config Complete |
| synapse + maubot (2 containers) | PostgreSQL | matrix.ruinous.social | Medium | Pending |
| rustdesk (2 containers) | None | Direct ports (21115-21117) | Simple | Pending |
| mastodon (3 containers) | PostgreSQL + Redis | ruinous.social (root) | Complex | Pending |

## Migration Strategy

**Approach:** One service at a time, verify before moving to next
**Data transfer:** Decide per service (rsync vs restic based on size/urgency)
**Mastodon:** Check media file size before proceeding

## Migration Order

Execute one service at a time to minimize risk:

1. **albyhub** - Standalone, no secrets needed
2. **baikal** - Standalone, no secrets needed
3. **mealie** - Standalone, has env secrets
4. **writefreely** - Standalone, config file only
5. **karakeep** - 3 containers, shared env secrets
6. **mastodon** - 3 containers, PostgreSQL migration, federation-critical

---

## Per-Service Migration Steps

### Service 1: AlbyHub

**Data to migrate:**
- `/data/docker/albyhub/data/` (SQLite wallet data)

**Steps:**
1. [ ] Stop container on tty.ruinous.social
2. [ ] Create directory on pilaster: `ssh pilaster "sudo mkdir -p /data/docker/albyhub/data"`
3. [ ] Transfer data via rsync or restore from restic
4. [ ] Add container definition to `hosts/pilaster/containers.nix`
5. [ ] Create Cloudflare tunnel: `cloudflared tunnel create alby-ruinous`
6. [ ] Encrypt tunnel credentials with agenix
7. [ ] Add tunnel to `hosts/pilaster/cloudflared.nix`
8. [ ] Update Caddyfile with `alby-int.ruinous.social alby.ruinous.social`
9. [ ] Create DNS: `alby-int.ruinous.social` CNAME to pilaster.meskill.farm
10. [ ] Deploy: `nixos-rebuild switch --flake .#pilaster`
11. [ ] Update DNS: `alby.ruinous.social` CNAME to tunnel
12. [ ] Verify access via tunnel
13. [ ] Remove container from tty-ruinous-social

**Container config:**
```nix
albyhub = {
  image = "ghcr.io/getalby/hub:v1.21.2";
  environment = {
    WORK_DIR = "/data/albyhub";
    TZ = "America/Phoenix";
  };
  networks = ["servicenet"];
  volumes = ["/data/docker/albyhub/data:/data"];
};
```

---

### Service 2: Baikal

**Data to migrate:**
- `/data/docker/baikal/config/`
- `/data/docker/baikal/specific/` (CalDAV/CardDAV data)

**Steps:** Same pattern as AlbyHub

**Container config:**
```nix
baikal = {
  image = "docker.io/ckulka/baikal:0.10.1-nginx-php8.2";
  networks = ["servicenet"];
  volumes = [
    "/data/docker/baikal/config:/var/www/baikal/config"
    "/data/docker/baikal/specific:/var/www/baikal/Specific"
  ];
};
```

---

### Service 3: Mealie

**Data to migrate:**
- `/data/docker/mealie/data/`

**Secrets to migrate:**
- `tty_ruinous_social_docker_env_mealie` → `pilaster_docker_env_mealie`

**Steps:** Same pattern + copy/re-encrypt env file

**Container config:**
```nix
mealie = {
  image = "ghcr.io/mealie-recipes/mealie:v3.8.0";
  environmentFiles = [config.age.secrets.pilaster_docker_env_mealie.path];
  networks = ["servicenet"];
  volumes = ["/data/docker/mealie/data:/app/data"];
};
```

---

### Service 4: WriteFreely

**Data to migrate:**
- `/data/docker/writefreely/keys/` (federation keys - CRITICAL)
- `/data/docker/writefreely/db/` (SQLite)
- `/data/docker/writefreely/config.ini`

**Note:** May need to update URLs in config.ini

**Container config:**
```nix
writefreely = {
  image = "docker.io/writeas/writefreely:0.16.0";
  networks = ["servicenet"];
  volumes = [
    "/data/docker/writefreely/keys:/go/keys"
    "/data/docker/writefreely/db:/db"
    "/data/docker/writefreely/config.ini:/go/config.ini"
  ];
};
```

---

### Service 5: Karakeep Stack

**Containers:** karakeep, karakeep-chrome, karakeep-meilisearch

**Data to migrate:**
- `/data/docker/karakeep/data/`
- `/data/docker/karakeep/meili_data/`

**Secrets to migrate:**
- `tty_ruinous_social_docker_env_karakeep` → `pilaster_docker_env_karakeep`

**Container configs:**
```nix
karakeep = {
  image = "ghcr.io/karakeep-app/karakeep:release";
  environmentFiles = [config.age.secrets.pilaster_docker_env_karakeep.path];
  networks = ["servicenet"];
  volumes = ["/data/docker/karakeep/data:/data"];
};

"karakeep-chrome" = {
  image = "gcr.io/zenika-hub/alpine-chrome:124";
  networks = ["servicenet"];
  cmd = ["--no-sandbox" "--disable-gpu" "--disable-dev-shm-usage"
         "--remote-debugging-address=0.0.0.0" "--remote-debugging-port=9222" "--hide-scrollbars"];
};

"karakeep-meilisearch" = {
  image = "docker.io/getmeili/meilisearch:v1.31.0";
  environmentFiles = [config.age.secrets.pilaster_docker_env_karakeep.path];
  networks = ["servicenet"];
  volumes = ["/data/docker/karakeep/meili_data:/meili_data"];
};
```

---

### Service 6: Synapse + Maubot (Matrix)

**Containers:** synapse, maubot

**Data to migrate:**
- PostgreSQL database: `synapse`
- `/data/docker/synapse/data/` (media, signing keys)
- `/data/docker/maubot/data/`

**Secrets to migrate:**
- `tty_ruinous_social_docker_env_synapse` → `pilaster_docker_env_synapse`
- Update DB_HOST to point to pilaster's postgres

**Container configs:**
```nix
synapse = {
  image = "ghcr.io/element-hq/synapse:v1.144.0";
  environmentFiles = [config.age.secrets.pilaster_docker_env_synapse.path];
  networks = ["datanet" "servicenet"];
  dependsOn = ["postgres"];
  volumes = ["/data/docker/synapse/data:/data"];
};

maubot = {
  image = "dock.mau.dev/maubot/maubot:v0.6.0";
  networks = ["servicenet"];
  volumes = ["/data/docker/maubot/data:/data"];
};
```

**Caddy config for Matrix:**
```
matrix-int.ruinous.social matrix.ruinous.social {
  reverse_proxy /_matrix/maubot/* maubot:29316
  reverse_proxy /_matrix/* synapse:8008
  reverse_proxy /_synapse/client/* synapse:8008
  reverse_proxy /_synapse/admin/* synapse:8008
}
```

---

### Service 7: RustDesk Relay

**Containers:** rustdesk-hbbr, rustdesk-hbbs

**Note:** RustDesk requires direct port access (UDP), cannot use Cloudflare tunnel.
Pilaster is behind NAT, so this may need port forwarding or Tailscale.

**Data to migrate:**
- `/data/docker/rustdesk/config/` (keys and config)

**Container configs:**
```nix
"rustdesk-hbbr" = {
  image = "docker.io/rustdesk/rustdesk-server:1.1.14";
  cmd = ["hbbr"];
  networks = ["proxynet"];
  ports = ["21117:21117"];
  environment = {ALWAYS_USE_RELAY = "Y";};
  volumes = ["/data/docker/rustdesk/config:/root"];
};

"rustdesk-hbbs" = {
  image = "docker.io/rustdesk/rustdesk-server:1.1.14";
  cmd = ["hbbs"];
  networks = ["proxynet"];
  ports = ["21115:21115" "21116:21116" "21116:21116/udp"];
  dependsOn = ["rustdesk-hbbr"];
  environment = {ALWAYS_USE_RELAY = "Y";};
  volumes = ["/data/docker/rustdesk/config:/root"];
};
```

**Firewall ports needed:**
```nix
networking.firewall.allowedTCPPorts = [21115 21116 21117];
networking.firewall.allowedUDPPorts = [21116];
```

---

### Service 8: Mastodon Stack (Most Complex)

**Containers:** mastodon-web, mastodon-streaming, mastodon-sidekiq

**Data to migrate:**
- PostgreSQL database: `mastodon_production`
- `/data/docker/mastodon/public/system/` (media files - could be large!)

**Secrets to migrate:**
- `tty_ruinous_social_docker_env_mastodon` → `pilaster_docker_env_mastodon`
- Update DB_HOST, REDIS_HOST to point to pilaster's postgres/redis

**Database migration steps:**
1. [ ] Stop Mastodon containers on tty.ruinous.social
2. [ ] Export database: `pg_dump -U postgres mastodon_production > mastodon.sql`
3. [ ] Create database on pilaster's PostgreSQL 18
4. [ ] Import database
5. [ ] Transfer media files (check size first!)
6. [ ] Copy and update env file (change DB_HOST=postgres, REDIS_HOST=redis)
7. [ ] Encrypt env file for pilaster

**Container configs:**
```nix
"mastodon-web" = {
  image = "ghcr.io/mastodon/mastodon:v4.5.3";
  environmentFiles = [config.age.secrets.pilaster_docker_env_mastodon.path];
  networks = ["datanet" "servicenet"];
  dependsOn = ["postgres" "redis"];
  cmd = ["bundle" "exec" "puma" "-C" "config/puma.rb"];
  volumes = ["/data/docker/mastodon/public/system:/mastodon/public/system"];
};

"mastodon-streaming" = {
  image = "ghcr.io/mastodon/mastodon-streaming:v4.5.3";
  environmentFiles = [config.age.secrets.pilaster_docker_env_mastodon.path];
  networks = ["datanet" "servicenet"];
  dependsOn = ["postgres" "redis"];
  cmd = ["node" "./streaming/index.js"];
};

"mastodon-sidekiq" = {
  image = "ghcr.io/mastodon/mastodon:v4.5.3";
  environmentFiles = [config.age.secrets.pilaster_docker_env_mastodon.path];
  networks = ["datanet" "servicenet"];
  dependsOn = ["postgres" "redis"];
  cmd = ["bundle" "exec" "sidekiq"];
  volumes = ["/data/docker/mastodon/public/system:/mastodon/public/system"];
};
```

**Caddy config for Mastodon (path-based routing):**
```
ruinous-int.ruinous.social ruinous.social {
  @streaming path /api/v1/streaming/*
  handle @streaming {
    reverse_proxy mastodon-streaming:4000
  }
  handle {
    reverse_proxy mastodon-web:3000
  }
}
```

**DNS for root domain:**
- Remove A/AAAA records for ruinous.social
- Add CNAME `@` → `<tunnel-id>.cfargotunnel.com` (proxied)

---

## Cloudflare Tunnel Strategy

Create 5 new tunnels on pilaster:

| Tunnel Name | Domains |
|-------------|---------|
| alby-ruinous | alby.ruinous.social |
| dav-ruinous | dav.ruinous.social |
| personal-ruinous | meals.ruinous.social, blog.ruinous.social |
| karakeep-ruinous | hoarder.ruinous.social, karakeep.ruinous.social |
| mastodon-ruinous | ruinous.social |

---

## Files to Modify

### hosts/pilaster/containers.nix
- Add: albyhub, baikal, mealie, writefreely
- Add: karakeep, karakeep-chrome, karakeep-meilisearch
- Add: mastodon-web, mastodon-streaming, mastodon-sidekiq
- Add: age.secrets entries for mealie, karakeep, mastodon

### hosts/pilaster/cloudflared.nix
- Add 5 new tunnel configurations
- Add 5 new age.secrets entries for tunnel credentials

### hosts/pilaster/files/caddy/Caddyfile.age
- Add reverse proxy entries for all new services
- Use `*-int.ruinous.social` pattern for internal domains

### New encrypted files to create
- `hosts/pilaster/files/docker/env/mealie.env.age`
- `hosts/pilaster/files/docker/env/karakeep.env.age`
- `hosts/pilaster/files/docker/env/mastodon.env.age`
- `hosts/pilaster/files/cloudflared/alby-ruinous.json.age`
- `hosts/pilaster/files/cloudflared/dav-ruinous.json.age`
- `hosts/pilaster/files/cloudflared/personal-ruinous.json.age`
- `hosts/pilaster/files/cloudflared/karakeep-ruinous.json.age`
- `hosts/pilaster/files/cloudflared/mastodon-ruinous.json.age`

---

## Data Transfer Options

### Option A: Direct rsync over SSH
```bash
rsync -avz --progress jmeskill@tty.ruinous.social:/data/docker/<service>/ /data/docker/<service>/
```

### Option B: Restore from restic backup
```bash
# Find latest snapshot
restic -r <repo> snapshots --host tty-ruinous-social

# Restore specific paths
restic -r <repo> restore <snapshot-id> --target /data/docker/ --include /data/docker/<service>/
```

---

## Rollback Plan

For each service, if migration fails:
1. Stop container on pilaster
2. Revert DNS to point back to tty.ruinous.social
3. Start container on tty.ruinous.social

---

## Post-Migration Cleanup

After 1 week of successful operation:
1. Remove migrated containers from `hosts/tty-ruinous-social/containers.nix`
2. Delete data directories on tty.ruinous.social
3. Update `hosts/pilaster/README.md` with new services
4. Update `hosts/tty-ruinous-social/README.md` noting migrations

---

## Resume Instructions

To continue this migration in a new session:
1. Check current status in this file (Service Status table above)
2. Run: `claude` in the nix-config directory
3. Say: "Continue the tty-ruinous-social to pilaster migration from docs/migrations/tty-ruinous-social-to-pilaster.md"
