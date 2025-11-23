# pilaster

Lightweight NixOS server for Docker containers and network services.

## Hardware

- **Model**: Minisforum MS-01
- **Platform**: x86_64-linux
- **CPU**: Intel 13th Gen i9-13900H (24 cores, KVM support)
- **Memory**: 96 GB RAM
- **Network**: Dual 2.5GbE ethernet, VLAN 2 support, Thunderbolt
- **Storage**: NVMe with Disko management
- **IP Address**: 10.55.20.25/24 (VLAN 2)

## Key Features

### Networking
- VLAN 2 (services network): 10.55.20.25/24
- systemd-networkd configuration
- nftables firewall
- Tailscale VPN with subnet routing (10.55.0.0/16)

### Services
- **Docker**: Container runtime
- **NFS**: Network file storage
- **Backup**: Restic backups to terranas
- **Monitoring**: Grafana Alloy for observability and journal logging

### Development
- Developer tools and environment

### Security & Management
- Plymouth boot splash
- Firmware updates via fwupd

## Purpose

Streamlined server focused on running Docker containers and providing network services. Works alongside other infrastructure servers (monolith, obelisk) to distribute workloads. Configured with essential monitoring and backup capabilities while maintaining a minimal service footprint.

## Managing Container Environment Files

Container environment variables are stored in encrypted files using agenix for security. This section documents the process for adding or updating container environment files.

### Adding a New Container with Environment Variables

When adding a new container to `containers.nix` that requires environment variables:

1. **Add the age secret declaration** to `containers.nix`:
   ```nix
   age.secrets.pilaster_docker_env_<container_name> = {
     rekeyFile = ./files/docker/env/<container_name>.env.age;
     mode = "600";
   };
   ```

2. **Create a temporary environment file** with your variables:
   ```bash
   cat > /tmp/<container_name>.env << 'EOF'
   VARIABLE_NAME=value
   ANOTHER_VAR=another_value
   EOF
   ```

3. **Encrypt the file using agenix**:
   ```bash
   agenix edit --input /tmp/<container_name>.env hosts/pilaster/files/docker/env/<container_name>.env.age
   rm /tmp/<container_name>.env
   ```

4. **Add the encrypted file to git**:
   ```bash
   git add hosts/pilaster/files/docker/env/<container_name>.env.age
   ```

5. **Rekey all secrets** (requires interactive authentication):
   ```bash
   agenix rekey -a
   ```

6. **Add the rekeyed secret to git**:
   ```bash
   git add secrets/nixos/pilaster/
   ```

7. **Update the container definition** to use `environmentFiles`:
   ```nix
   <container_name> = {
     image = "...";
     environmentFiles = [config.age.secrets.pilaster_docker_env_<container_name>.path];
     # ... other container config
   };
   ```

8. **Test the configuration**:
   ```bash
   nixos-rebuild dry-build --flake .#pilaster
   ```

### Example: nutify Container

The nutify container demonstrates this pattern:

- Age secret: `age.secrets.pilaster_docker_env_nutify`
- Encrypted file: `hosts/pilaster/files/docker/env/nutify.env.age`
- Rekeyed secret: `secrets/nixos/pilaster/*-pilaster_docker_env_nutify.age`
- Container config uses: `environmentFiles = [config.age.secrets.pilaster_docker_env_nutify.path];`

### Security Notes

- Never commit unencrypted `.env` files to git
- Always clean up temporary files after encryption
- Change default/test values (like `SECRET_KEY=test1234567890`) to secure random values
- The `mode = "600"` ensures only the root user can read the decrypted secrets
