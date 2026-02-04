# Secrets Management

> Encrypted secrets using agenix with agenix-rekey integration.

**Full patterns:** See [NIXEY SME](https://agents.ruinous.ai/smes/nixey/) or the `/encrypt-secret` skill.

## Quick Reference

### Commands

```bash
just unlock            # Enter passphrase once per session
just peek <path>       # View an encrypted secret
just encrypt <path>    # Create or edit an encrypted secret
just rekey             # Re-encrypt all secrets
agenix-helper lock     # When done with secrets work
```

### View

```bash
just peek path/to/file.age
```

### Edit Workflow

```bash
just peek file.age > /tmp/edit.txt
# ... modify /tmp/edit.txt ...
rm file.age
agenix edit -i /tmp/edit.txt file.age
rm /tmp/edit.txt
just rekey
```

### Create New

```bash
# From template
agenix edit -i template.txt output.age
# Interactive
just encrypt output.age
```

## File Locations

| Purpose | Path Pattern |
|---------|--------------|
| Caddyfiles | `hosts/<host>/files/caddy/Caddyfile.age` |
| Docker env | `hosts/<host>/files/docker/env/<service>.env.age` |
| Cloudflared certs | `hosts/<host>/files/cloudflared/cert.pem.age` |
| Cloudflared tunnels | `hosts/<host>/files/cloudflared/<tunnel>.json.age` |

## Secret Naming Convention

```nix
age.secrets.<hostname>_<purpose> = {
  rekeyFile = ./files/<path>.age;
  mode = "600";
};
```

Examples:
- `zenith_caddy_caddyfile`
- `monolith_docker_env_n8n`
- `pilaster_cloudflared_cert_pem`

## Rekeyed Output

After `agenix rekey -a`, encrypted secrets land in:
```
secrets/nixos/<hostname>/<hash>-<secret_name>.age
```

## Container Environment Pattern

```nix
# In containers.nix
virtualisation.oci-containers.containers.myservice = {
  image = "registry/image:tag";
  environmentFiles = [config.age.secrets.<host>_docker_env_myservice.path];
  # ...
};

age.secrets.<host>_docker_env_myservice = {
  rekeyFile = ./files/docker/env/myservice.env.age;
  mode = "600";
};
```

## Caddyfile Pattern

```nix
# Mount encrypted Caddyfile
age.secrets.<host>_caddy_caddyfile = {
  rekeyFile = ./files/caddy/Caddyfile.age;
  mode = "644";
};

# Restart Caddy on change
systemd.services.docker-caddy = {
  restartTriggers = [config.age.secrets.<host>_caddy_caddyfile.path];
};
```

## Cloudflared Pattern

```nix
age.secrets.<host>_cloudflared_cert_pem = {
  rekeyFile = ./files/cloudflared/cert.pem.age;
  path = "/etc/cloudflared/cert.pem";
  mode = "644";
};

age.secrets.<host>_cloudflared_<tunnel> = {
  rekeyFile = ./files/cloudflared/<tunnel>.json.age;
  mode = "644";
};
```

## Best Practices

1. **Always unlock first** - `just unlock` before any secrets work
2. **Always rekey** after modifying any `.age` file: `just rekey`
3. **Never commit plaintext** - verify with `git status` before committing
4. **Use /tmp for temporary files** during edit workflow
5. **Lock when done** - `agenix-helper lock`
6. **Document secret purpose** in Nix comments

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied | Run `just unlock` |
| Rekey fails | Check host keys in secrets.nix |
| Secret not available | Verify `age.secrets.<name>` definition |
| Container can't read | Check `mode` and `environmentFiles` path |
