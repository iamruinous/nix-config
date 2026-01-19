---
name: deploy-container
description: Full workflow to deploy a Docker container with secrets, Caddy, and DNS
compatibility: Requires agenix, cfcli, nix
metadata:
  author: ruinous.ai
  version: "1.1"
  domain: containers
parameters:
  service_name:
    type: string
    description: Name for the service (used for container, database, DNS)
    required: true
    placeholder: "myapp"
  hostname:
    type: select
    description: Target host for deployment
    required: true
    options:
      - label: "pilaster (Recommended)"
        description: "Main web services host"
      - label: "monolith"
        description: "Infrastructure services host"
      - label: "zenith"
        description: "AI/GPU workloads (AMD ROCm)"
      - label: "obelisk"
        description: "GPU compute (NVIDIA)"
  container_image:
    type: string
    description: Docker image with tag (avoid :latest)
    required: true
    placeholder: "ghcr.io/org/image:v1.0.0"
  needs_database:
    type: select
    description: Does this service need a PostgreSQL database?
    required: false
    default: "No"
    options:
      - label: "No"
        description: "No database needed"
      - label: "Yes"
        description: "Create database with same name as service"
  needs_reverse_proxy:
    type: select
    description: Should Caddy proxy requests to this service?
    required: false
    default: "Yes"
    options:
      - label: "Yes (Recommended)"
        description: "Add Caddy route for HTTPS access"
      - label: "No"
        description: "Internal only, no web access"
---

# Deploy Container

Complete workflow to deploy a new Docker container service with secrets, Caddy reverse proxy, and DNS.

## Parameter Handling

**If parameters are missing from `$ARGUMENTS`, use `mcp_question` to gather them:**

```
mcp_question({
  questions: [
    {
      question: "What should the service be named?",
      header: "Service",
      options: [
        { label: "Enter name...", description: "e.g., myapp (used for container, DNS, database)" }
      ]
    },
    {
      question: "Which host should run this container?",
      header: "Host",
      options: [
        { label: "pilaster (Recommended)", description: "Main web services host" },
        { label: "monolith", description: "Infrastructure services" },
        { label: "zenith", description: "AI/GPU (AMD ROCm)" },
        { label: "obelisk", description: "GPU compute (NVIDIA)" }
      ]
    },
    {
      question: "What is the container image?",
      header: "Image",
      options: [
        { label: "Enter image...", description: "e.g., ghcr.io/org/image:v1.0.0" }
      ]
    },
    {
      question: "Does this service need a database?",
      header: "Database",
      options: [
        { label: "No", description: "No database needed" },
        { label: "Yes", description: "Create PostgreSQL database" }
      ]
    }
  ]
})
```

**Expected `$ARGUMENTS` format:** `<service_name> <hostname> <container_image>`
- Example: `myapp pilaster ghcr.io/org/myapp:1.0.0`

## Prerequisites Checklist

- [ ] Which host? (monolith, pilaster, zenith, obelisk)
- [ ] Needs secrets/environment variables?
- [ ] Needs reverse proxy (Caddy)?
- [ ] Needs external access (Cloudflare tunnel)?
- [ ] Needs database? (use `/initialize-pgdb`)
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
/initialize-pgdb <hostname> <service>
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
