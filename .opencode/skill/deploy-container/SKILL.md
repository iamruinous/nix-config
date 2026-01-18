---
name: deploy-container
description: Full workflow to deploy a Docker container with secrets, Caddy, and DNS
compatibility: Requires agenix, cfcli, nix
metadata:
  author: ruinous.ai
  version: "1.0"
  domain: containers
---

# Deploy Container

Complete workflow to deploy a new Docker container service with secrets, Caddy reverse proxy, and DNS.

**Arguments:** `$ARGUMENTS` should contain:
- Service name (e.g., `myapp`)
- Target host (e.g., `pilaster`, `monolith`, `zenith`)
- Container image (e.g., `registry/image:tag`)

## Prerequisites Checklist

- [ ] Which host? (monolith, pilaster, zenith, obelisk)
- [ ] Needs secrets/environment variables?
- [ ] Needs reverse proxy (Caddy)?
- [ ] Needs external access (Cloudflare tunnel)?
- [ ] Needs database? (use `/create-db-<host>`)
- [ ] GPU access? (zenith=AMD ROCm, obelisk=NVIDIA)

## Full Deployment Steps

### 1. Unlock agenix
```bash
agenix-helper unlock
```

### 2. Create directory structure
```bash
mkdir -p hosts/<hostname>/files/docker/env
```

### 3. Create database (if needed)
```bash
/create-db-<hostname> <service>
```

### 4. Create environment file (if needed)
```bash
cat > /tmp/<service>.env << 'EOF'
DATABASE_URL=postgres://<service>:<password>@postgres:5432/<service>
API_KEY=
SECRET_KEY=
EOF

# Encrypt
agenix edit -i /tmp/<service>.env hosts/<hostname>/files/docker/env/<service>.env.age
rm /tmp/<service>.env
```

### 5. Add container to containers.nix

```nix
virtualisation.oci-containers.containers.<service> = {
  image = "registry/image:tag";
  environmentFiles = [config.age.secrets.<hostname>_docker_env_<service>.path];
  networks = ["servicenet"];
  volumes = ["/data/docker/<service>/data:/app/data"];
  dependsOn = ["postgres"];  # if using database
};

age.secrets.<hostname>_docker_env_<service> = {
  rekeyFile = ./files/docker/env/<service>.env.age;
  mode = "600";
};
```

### 6. Update Caddyfile (if reverse proxy needed)
Use `/add-caddy-route` skill or manually:

```bash
agenix view hosts/<hostname>/files/caddy/Caddyfile.age > /tmp/Caddyfile
echo '<service>.meskill.farm {
  reverse_proxy <service>:8080
}' >> /tmp/Caddyfile
rm hosts/<hostname>/files/caddy/Caddyfile.age
agenix edit -i /tmp/Caddyfile hosts/<hostname>/files/caddy/Caddyfile.age
rm /tmp/Caddyfile
```

### 7. Rekey secrets
```bash
agenix rekey -a
```

### 8. Create DNS entry
```bash
cfcli --domain meskill.farm --type CNAME add <service> <hostname>.meskill.farm
```

### 9. Lock agenix
```bash
agenix-helper lock
```

### 10. Commit and deploy
```bash
git add .
git commit -S -m "feat: add <service> container to <hostname>"
just remote-rebuild <hostname>
```

## Network Selection

| Network | Purpose | Use For |
|---------|---------|---------|
| `servicenet` | Inter-container + Caddy | Web apps |
| `datanet` | Internal only (--internal) | Databases, caches |
| `proxynet` | Host port binding | Caddy, UDP services |

## Container Patterns

### Web App with Database
```nix
networks = ["servicenet" "datanet"];
dependsOn = ["postgres"];
```

### GPU Container (NVIDIA - obelisk)
```nix
devices = ["nvidia.com/gpu=all"];
```

### GPU Container (AMD ROCm - zenith)
```nix
extraOptions = [
  "--device=/dev/kfd"
  "--device=/dev/dri"
  "--security-opt=seccomp=unconfined"
];
environment = {
  HSA_OVERRIDE_GFX_VERSION = "11.0.0";
};
```

## Example

```bash
/deploy-container myapp pilaster ghcr.io/org/myapp:1.0.0
```

## Post-Deployment

- [ ] Verify container running: `docker ps | grep <service>`
- [ ] Check logs: `docker logs <service>`
- [ ] Test via Caddy: `curl https://<service>.meskill.farm`
- [ ] Add to Gatus monitoring (hosts/monolith/files/gatus/config.yaml)
