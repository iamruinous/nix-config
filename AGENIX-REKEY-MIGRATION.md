# Agenix-Rekey Migration Summary

## ✅ Completed Steps

### 1. Master Age Key Created

**Location:** `secrets/master-keys/`
- Private key: `master.age` (gitignored)
- Public key: `master.pub`
- **Public Key:** `age17tu85cfnjkqcx9u458qfedrj88credzqpa44hs9lzklhg5m8kaesrqsxfd`

**⚠️ IMPORTANT:** Store the private key (`secrets/master-keys/master.age`) securely:
- Back it up to a password manager
- Keep it separate from version control
- You'll need it to rekey secrets

### 2. Flake Configuration Updated

**File:** `flake.nix`
- Added `agenix-rekey` input (line 67-70)
- Configured output to expose agenix-rekey CLI (line 137-140)
- Both nixosModules and darwinModules now import agenix-rekey

### 3. Per-Host Configuration Modules Created

**NixOS Module:** `modules/nixos/default/agenix-rekey.nix`
**Darwin Module:** `modules/darwin/default/agenix-rekey.nix`

These modules automatically configure each host with:
- Host SSH public key
- Master age identity reference
- Local storage directory for rekeyed secrets
- SSH-ed25519 age plugin support

**Configured Hosts:**
- framework, monolith, obelisk, pilaster (NixOS - with keys)
- jmacmini, studio (macOS - with keys)
- gap, void, ruinous-tty, messy-tty, jbookpro (placeholder keys - need updating)

### 4. Common Agenix Module Updated

**File:** `modules/nixos/common/agenix.nix`
- Added `agenix-rekey.nixosModules.default` import (line 8)

### 5. Secret Declarations Converted

**Total:** 46 secret declarations converted
- Changed from `age.secrets.*.file =`
- To `age.secrets.*.rekeyFile =`

**Files Modified:**
- modules/home/default/vdirsyncer.nix
- modules/home/default/todoist.nix
- modules/nixos/default/restic.nix
- modules/nixos/default/libvirt.nix
- modules/nixos/default/caddy.nix
- hosts/monolith/* (containers.nix, configuration.nix, cloudflared.nix, rtl_433.nix, vm.nix, users/git/home-configuration.nix)
- hosts/obelisk/containers.nix
- hosts/pilaster/containers.nix
- hosts/tty-ruinous-social/containers.nix

### 6. Gitignore Updated

Added to `.gitignore`:
```
# Agenix-rekey sensitive files
secrets/master-keys/*.age
secrets/rekeyed/
```

## 📋 Next Steps

### Step 1: Update Missing Host Keys

Hosts with placeholder SSH keys need their actual keys added:

```bash
# SSH into each host and get its SSH host key
ssh root@hostname "cat /etc/ssh/ssh_host_ed25519_key.pub"
```

Update these files with the actual keys:
- `modules/nixos/default/agenix-rekey.nix` (for gap, void, ruinous-tty, messy-tty)
- `modules/darwin/default/agenix-rekey.nix` (for jbookpro)

### Step 2: Run Initial Rekey

From your development machine with access to `master.age`:

```bash
# Test that agenix-rekey is available
nix run .#agenix-rekey.x86_64-darwin.rekey -- --help

# Rekey all secrets for all configured hosts
AGE_IDENTITY_FILE=secrets/master-keys/master.age \
  nix run .#agenix-rekey.x86_64-darwin.rekey -- --all

# Or rekey for a specific host
AGE_IDENTITY_FILE=secrets/master-keys/master.age \
  nix run .#agenix-rekey.x86_64-darwin.rekey -- -h framework
```

This will create `secrets/rekeyed/<hostname>/` directories with rekeyed secrets.

### Step 3: Test on One Host

Pick a non-critical host to test first (e.g., framework):

```bash
# Build configuration
nixos-rebuild build --flake .#framework

# If successful, switch
nixos-rebuild switch --flake .#framework
```

Verify that:
- The system builds successfully
- Secrets are accessible to services
- Services using secrets start correctly

### Step 4: Deploy to All Hosts

Once verified on one host:

```bash
# For each NixOS host
nixos-rebuild switch --flake .#<hostname>

# For macOS hosts
darwin-rebuild switch --flake .#<hostname>
```

### Step 5: Remove secrets.nix

After all hosts are successfully running with agenix-rekey:

```bash
git rm secrets/secrets.nix
git commit -m "Remove secrets.nix - migrated to agenix-rekey"
```

## 🎯 Benefits Achieved

1. **No more secrets.nix maintenance** - hosts automatically get secrets they declare
2. **Improved security** - master key protects against leaked host keys
3. **Automatic rekeying** - only re-encrypts when necessary
4. **Easier host management** - adding hosts doesn't require updating secret mappings

## 📝 New Workflow

### Editing Secrets

```bash
# Old way
EDITOR=nvim agenix -e files/configs/restic/restic-password.age

# New way
AGE_IDENTITY_FILE=secrets/master-keys/master.age \
  nix run .#agenix-rekey.x86_64-darwin.edit-view -- files/configs/restic/restic-password.age
```

### Adding a Secret to a Host

Just declare it in the host configuration:

```nix
age.secrets.my_secret = {
  rekeyFile = ../../files/configs/my-secret.age;
  mode = "600";
};
```

Then rekey:

```bash
AGE_IDENTITY_FILE=secrets/master-keys/master.age \
  nix run .#agenix-rekey.x86_64-darwin.rekey -- -h hostname
```

### Creating New Secrets

```bash
# Create and edit a new secret
AGE_IDENTITY_FILE=secrets/master-keys/master.age \
  nix run .#agenix-rekey.x86_64-darwin.edit-view -- files/configs/new-secret.age
```

## ⚠️ Important Notes

- Keep `secrets/master-keys/master.age` safe - it's the key to all secrets
- The `secrets/rekeyed/` directory will be auto-generated and is gitignored
- Hosts need the agenix-rekey module imported (done automatically via default modules)
- Each host's rekeyed secrets are stored in `secrets/rekeyed/<hostname>/`

## 🔍 Troubleshooting

### "Node X is missing the agenix-rekey module"

Make sure the host imports either:
- `flake.nixosModules.default` (for NixOS)
- `flake.darwinModules.default` (for macOS)

### "Host key not found"

Update the host's SSH public key in:
- `modules/nixos/default/agenix-rekey.nix` (NixOS)
- `modules/darwin/default/agenix-rekey.nix` (macOS)

### Secrets not accessible after rekey

1. Verify rekeyed secrets exist: `ls secrets/rekeyed/<hostname>/`
2. Check host configuration includes agenix-rekey module
3. Rebuild with `--show-trace` for detailed errors
