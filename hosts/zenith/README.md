# zenith

NixOS server for Docker containers and network services.

## Hardware

- **Model**: Minisforum MS-S1 MAX
- **Platform**: x86_64-linux
- **CPU**: AMD Ryzen AI Max+ 395 (16 Zen 5 cores, 32 threads, 3.0-5.1 GHz, KVM support)
- **Memory**: 128GB LPDDR5x-8000 (soldered)
- **GPU**: Radeon 8060S (40 RDNA 3.5 Compute Units, up to 2.9 GHz)
- **NPU**: 50 TOPS (126 TOPS total AI performance)
- **Network**: Dual 10GbE LAN (Realtek RTL8127), VLAN 2 support
- **Storage**: NVMe with Disko management (btrfs), dual M.2 slots
- **IP Address**: 10.55.20.21/24 (VLAN 2)

## Key Features

### Networking
- VLAN 2 (services network): 10.55.20.21/24
- systemd-networkd configuration
- nftables firewall
- Tailscale VPN with subnet routing (10.55.0.0/16)

### Virtualization & Containers
- Docker with btrfs storage driver
- Container orchestration with multiple networks:
  - **servicenet**: Inter-container communication
  - **proxynet**: Services exposed via Caddy
  - **datanet**: Internal-only network for databases

### Services
- **Caddy**: Reverse proxy with Cloudflare DNS and HTTPS
- **MCP Gateway**: Model Context Protocol gateway for AI tool integration (mcp.x.meskill.farm)
- **Open WebUI**: Web interface for Ollama (ai.x.meskill.farm)
- **Ollama**: Local LLM inference with AMD ROCm GPU support (ollama.x.meskill.farm)

### Development
- Developer tools and environment

### Security & Management
- Firmware updates via fwupd

## Purpose

Server running Docker containers with Caddy reverse proxy for web services. Uses Tailscale for secure remote access with subnet routing capabilities.

## Managing Container Environment Files

Container environment variables are stored in encrypted files using agenix for security. This section documents the process for adding or updating container environment files.

### Adding a New Container with Environment Variables

When adding a new container to `containers.nix` that requires environment variables:

1. **Add the age secret declaration** to `containers.nix`:
   ```nix
   age.secrets.zenith_docker_env_<container_name> = {
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
   agenix edit --input /tmp/<container_name>.env hosts/zenith/files/docker/env/<container_name>.env.age
   rm /tmp/<container_name>.env
   ```

4. **Add the encrypted file to git**:
   ```bash
   git add hosts/zenith/files/docker/env/<container_name>.env.age
   ```

5. **Rekey all secrets** (requires interactive authentication):
   ```bash
   agenix rekey -a
   ```

6. **Add the rekeyed secret to git**:
   ```bash
   git add secrets/nixos/zenith/
   ```

7. **Update the container definition** to use `environmentFiles`:
   ```nix
   <container_name> = {
     image = "...";
     environmentFiles = [config.age.secrets.zenith_docker_env_<container_name>.path];
     # ... other container config
   };
   ```

8. **Test the configuration**:
   ```bash
   nixos-rebuild dry-build --flake .#zenith
   ```

### Security Notes

- Never commit unencrypted `.env` files to git
- Always clean up temporary files after encryption
- The `mode = "600"` ensures only the root user can read the decrypted secrets
