# builder-tty

Automation MicroVM for docs package updates triggered by Forgejo webhooks.

## Hardware

- **Physical Host**: obelisk (Alienware Aurora R16)
- **Platform**: x86_64-linux
- **Type**: MicroVM (QEMU hypervisor)
- **Resources**: 4 CPU cores, 4096 MB RAM
- **Network**: macvtap interface on VLAN 2 (MAC: 02:02:00:00:00:10)

## Purpose

Handles automated nix package updates when docs repositories are tagged:

1. **n8n receives webhook** from Forgejo on tag push
2. **n8n SSHs into builder-tty** with repo/tag info
3. **builder-tty runs update script**:
   - Fetches new hash via `nix-prefetch-git`
   - Updates package version and hash
   - Creates branch, commits (signed), pushes
   - Creates PR via `gh` CLI
4. **n8n posts result** to Discord

## Supported Repositories

| Repository | Package | Site |
|------------|---------|------|
| messy-docs | `packages/messy-docs` | https://messy.ruinous.ai |
| newsy-docs | `packages/newsy-docs` | https://newsy.ruinous.ai |
| codey-docs | `packages/codey-docs` | https://codey.ruinous.ai |

## Key Features

### MicroVM Configuration
- QEMU-based virtualization
- Writable Nix store overlay (20GB)
- Shared host Nix store via virtiofs (read-only)
- Persistent storage for git repos and credentials

### Impermanence
- Root filesystem is ephemeral (cleared on reboot)
- Selective persistence:
  - `~/Projects` - nix-config clone
  - `~/.gnupg` - GPG signing keys
  - `~/.ssh` - SSH keys for Forgejo
  - `~/.config/gh` - GitHub CLI auth
  - `~/bin` - Update scripts

### Credentials (Manual Setup Required)

After deployment, configure:

1. **GPG Signing Key**
   ```bash
   # Import the signing key
   gpg --import /path/to/signing-key.asc
   # Update ~/.gitconfig with key ID
   git config --global user.signingkey <KEY_ID>
   ```

2. **SSH Key for Forgejo**
   ```bash
   # Generate or copy SSH key
   ssh-keygen -t ed25519 -f ~/.ssh/forgejo_ed25519
   # Add public key to Forgejo account
   # Configure ~/.ssh/config:
   cat >> ~/.ssh/config << 'EOF'
   Host forge.meskill.farm
     IdentityFile ~/.ssh/forgejo_ed25519
     User git
   EOF
   ```

3. **GitHub CLI Authentication**
   ```bash
   gh auth login
   # Select: GitHub.com, SSH, authenticate
   ```

4. **Clone nix-config**
   ```bash
   mkdir -p ~/Projects
   cd ~/Projects
   git clone git@github.com:iamruinous/nix-config.git
   ```

5. **Install Update Script**
   ```bash
   mkdir -p ~/bin
   # Script will be deployed by n8n workflow setup
   ```

## Update Script

The update script (`~/bin/update-docs-package.sh`) handles:

```bash
./update-docs-package.sh <repo-name> <version> <tag>
# Example: ./update-docs-package.sh messy-docs 0.2.0 v0.2.0
```

**Output**: JSON with success status and PR URL

**Actions**:
1. Fetch latest main branch
2. Check if PR already exists (idempotent)
3. Compute new hash via `nix-prefetch-git`
4. Update `packages/{repo}/default.nix`
5. Create branch `chore/update-{repo}-{version}`
6. Commit with signature
7. Push and create PR

## n8n Integration

The n8n workflow "Shared 2.0 - Update Docs Package" connects to this VM via SSH.

**Required n8n Credentials**:
- SSH credential with key that's in builder's `~/.ssh/authorized_keys`

**Workflow Location**: `n8n-agent/shared-2.0/workflows/update-docs-package/`

## Troubleshooting

### SSH Connection Failed
1. Verify builder-tty is running: `systemctl status microvm@builder-tty`
2. Check n8n has correct SSH key
3. Verify network connectivity from monolith

### Update Script Failed
1. Check script output for specific error
2. Verify git remotes are accessible
3. Check GPG key is available for signing
4. Verify gh CLI is authenticated

### PR Creation Failed
1. Check gh auth status: `gh auth status`
2. Verify branch doesn't already exist
3. Check GitHub API rate limits

## Network

- **IP**: Assigned via DHCP on VLAN 2
- **SSH Port**: 22
- **Access**: From n8n (monolith) via internal network

## Related

- [n8n Workflow README](../../docs/n8n-agent/shared-2.0/workflows/update-docs-package/README.md)
- [Forgejo Webhook Setup](../../docs/forgejo-webhooks.md)
- [messy-tty](../messy-tty/README.md) - Similar MicroVM for reference
