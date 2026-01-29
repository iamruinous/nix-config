# justfile for nix-config
# Run `just` to see available recipes

# Default recipe - show help
default:
    @just --list

# =============================================================================
# Helper Functions (private)
# =============================================================================

[private]
header title:
    @gum style --foreground 212 --bold "{{ title }}"

[private]
info msg:
    @gum log --level info "{{ msg }}"

[private]
warn msg:
    @gum log --level warn "{{ msg }}"

[private]
error msg:
    @gum log --level error "{{ msg }}"

[private]
success msg:
    @gum log --level info --prefix "✓" "{{ msg }}"

# =============================================================================
# Host Commands
# =============================================================================

# Verify configuration builds (dry-build)
[group('host')]
check host=`hostname`:
    #!/usr/bin/env bash
    set -euo pipefail
    current_host=$(hostname)
    os_type=$(uname -s)
    
    # Check if target is a Darwin host by looking for darwin-configuration.nix
    is_darwin_host=false
    if [ -f "hosts/{{ host }}/darwin-configuration.nix" ]; then
        is_darwin_host=true
    fi
    
    if [ "{{ host }}" = "$current_host" ]; then
        # Local verification
        if [ "$os_type" = "Darwin" ]; then
            just darwin-check
        else
            just local-check
        fi
    elif [ "$is_darwin_host" = "true" ]; then
        # Darwin hosts - use nix build --dry-run (can check remotely)
        just header "🧪 Darwin Check"
        just info "Dry-building darwin configuration for {{ host }}..."
        nix build .#darwinConfigurations.{{ host }}.system --dry-run
        just success "Check complete for {{ host }}"
    else
        # Remote NixOS
        just remote-check {{ host }}
    fi

# Deploy configuration to host
[group('host')]
deploy host=`hostname`:
    #!/usr/bin/env bash
    set -euo pipefail
    current_host=$(hostname)
    os_type=$(uname -s)
    
    # Check if target is a Darwin host by looking for darwin-configuration.nix
    is_darwin_host=false
    if [ -f "hosts/{{ host }}/darwin-configuration.nix" ]; then
        is_darwin_host=true
    fi
    
    if [ "{{ host }}" = "$current_host" ]; then
        # Local deployment
        if [ "$os_type" = "Darwin" ]; then
            just darwin-deploy
        else
            just local-deploy
        fi
    elif [ "$is_darwin_host" = "true" ]; then
        # Darwin hosts don't support remote deployment
        just error "Darwin hosts don't support remote deployment. Run 'just deploy' on {{ host }} directly."
        exit 1
    else
        # Remote NixOS deployment
        just remote-deploy {{ host }}
    fi

# Build configuration without switching
[group('host')]
build host=`hostname`:
    #!/usr/bin/env bash
    set -euo pipefail
    current_host=$(hostname)
    os_type=$(uname -s)
    
    # Check if target is a Darwin host by looking for darwin-configuration.nix
    is_darwin_host=false
    if [ -f "hosts/{{ host }}/darwin-configuration.nix" ]; then
        is_darwin_host=true
    fi
    
    if [ "{{ host }}" = "$current_host" ]; then
        # Local build
        if [ "$os_type" = "Darwin" ]; then
            just darwin-build
        else
            just local-build
        fi
    elif [ "$is_darwin_host" = "true" ]; then
        # Darwin hosts - can build remotely
        just header "🔨 Darwin Build"
        just info "Building darwin configuration for {{ host }}..."
        nix build .#darwinConfigurations.{{ host }}.system
        just success "Build complete for {{ host }}"
    else
        # Remote NixOS build
        just remote-build {{ host }}
    fi

# Bootstrap host with nixos-anywhere (initial installation)
[group('host')]
bringup host sshpass:
    #!/usr/bin/env bash
    set -euo pipefail
    just header "🚀 Bringup - nixos-anywhere"
    just info "Bootstrapping {{ host }} with nixos-anywhere..."
    just warn "This will ERASE the target system and install NixOS!"
    gum confirm "Bootstrap {{ host }}?" || exit 1
    env SSHPASS="{{ sshpass }}" nix run github:nix-community/nixos-anywhere -- \
        --flake .#{{ host }} \
        --target-host nixos@{{ host }}.meskill.farm \
        --env-password
    just success "Bringup complete for {{ host }}"

# Install Nix and nix-darwin (if on macOS)
[group('host')]
install:
    #!/usr/bin/env bash
    set -euo pipefail
    os_type=$(uname -s)
    
    just header "📦 Install"
    
    if [ "$os_type" = "Darwin" ]; then
        just info "Installing Lix (Nix fork) via lix-installer..."
        curl -sSf -L https://install.lix.systems/lix | sh -s -- install
        just success "Lix installation complete"
        
        just info "Installing nix-darwin for $(hostname)..."
        nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake .#$(hostname)
        just success "nix-darwin installation complete"
    else
        just info "Installing Nix package manager..."
        curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
        just success "Nix installation complete"
    fi

# =============================================================================
# Validation Commands
# =============================================================================

# Dry-build representative hosts (sanity check)
[group('validate')]
canary:
    @just header "🐤 Canary - Dry Build Representative Hosts"
    @just info "Testing NixOS desktop (chassis)..."
    @nix build .#nixosConfigurations.chassis.config.system.build.toplevel --dry-run 2>/dev/null
    @just success "chassis (NixOS desktop) OK"
    @just info "Testing NixOS laptop (framework)..."
    @nix build .#nixosConfigurations.framework.config.system.build.toplevel --dry-run 2>/dev/null
    @just success "framework (NixOS laptop) OK"
    @just info "Testing NixOS server (monolith)..."
    @nix build .#nixosConfigurations.monolith.config.system.build.toplevel --dry-run 2>/dev/null
    @just success "monolith (NixOS server) OK"
    @just info "Testing Darwin (jbookpro)..."
    @nix build .#darwinConfigurations.jbookpro.system --dry-run 2>/dev/null
    @just success "jbookpro (Darwin) OK"
    @just info "Testing Raspberry Pi 5 (rp500)..."
    @nix build .#nixosConfigurations.rp500.config.system.build.toplevel --dry-run 2>/dev/null
    @just success "rp500 (Raspberry Pi 5) OK"
    @just info "Testing Raspberry Pi 4 (rpc-4-echo)..."
    @nix build .#nixosConfigurations.rpc-4-echo.config.system.build.toplevel --dry-run 2>/dev/null
    @just success "rpc-4-echo (Raspberry Pi 4) OK"
    @echo ""
    @gum style --foreground 82 --bold "✓ All canary checks passed!"

# =============================================================================
# Secrets Commands
# =============================================================================

# Unlock agenix identity for secret operations
[group('secrets')]
unlock:
    @just header "🔓 Unlock Agenix"
    @agenix-helper unlock
    @just success "Agenix identity unlocked"

# View an encrypted secret
[group('secrets')]
peek secret:
    @just header "👁️  View Secret"
    @agenix view {{ secret }}

# Create or edit an encrypted secret
[group('secrets')]
encrypt secret:
    @just header "🔐 Edit Secret"
    @agenix edit {{ secret }}

# Re-encrypt all secrets for hosts that need them
[group('secrets')]
rekey:
    @just header "🔑 Rekey Secrets"
    @just info "Re-encrypting secrets for all hosts..."
    @agenix rekey -a
    @just success "Secrets rekeyed"
    @echo ""
    @gum style --foreground 229 "Don't forget to commit the rekeyed secrets:"
    @gum style --foreground 245 "  git add secrets/"

# =============================================================================
# RPi Image Commands
# =============================================================================

# Build Raspberry Pi SD image
[group('pi')]
sd-image host:
    #!/usr/bin/env bash
    set -euo pipefail
    just header "🥧 Build Raspberry Pi SD Image"
    just info "Building SD image for {{ host }} on armistice..."
    export NIX_SSHOPTS="-o SetEnv=BYPASS_LOGIN_HUB=true"
    nix build .#nixosConfigurations.{{ host }}.config.system.build.sdImage \
        --builders "ssh://armistice.meskill.farm aarch64-linux - 12 1 benchmark,big-parallel,kvm" \
        --max-jobs 0 \
        --cores 0 \
        --log-format bar-with-logs \
        -o result-{{ host }}-sdimage
    just success "SD image built: result-{{ host }}-sdimage/"
    @echo ""
    @gum style --foreground 229 "To flash to SD card:"
    @gum style --foreground 245 "  just sd-flash {{ host }} /dev/sdX"

# Flash Raspberry Pi SD image to device
[group('pi')]
sd-flash host device:
    #!/usr/bin/env bash
    set -euo pipefail
    just header "🥧 Flash Raspberry Pi SD Card"
    if [ ! -d "result-{{ host }}-sdimage" ]; then
        just error "result-{{ host }}-sdimage not found. Run 'just sd-image {{ host }}' first."
        exit 1
    fi
    if [ ! -b "{{ device }}" ]; then
        just error "{{ device }} is not a block device"
        exit 1
    fi
    just warn "This will erase all data on {{ device }}!"
    gum confirm "Flash {{ host }} image to {{ device }}?" || exit 1
    just info "Decompressing image..."
    gum spin --spinner dot --title "Decompressing {{ host }} image..." -- zstd -d -f result-{{ host }}-sdimage/sd-image/*.img.zst -o /tmp/{{ host }}.img
    just info "Flashing to {{ device }}..."
    sudo bmaptool copy --nobmap /tmp/{{ host }}.img {{ device }}
    sync
    rm -f /tmp/{{ host }}.img
    just success "Flash complete! You can safely remove {{ device }}."

# =============================================================================
# Utility Commands
# =============================================================================

# Update all flake inputs
[group('utility')]
update-flake:
    @just header "🔄 Update Flake"
    @gum spin --spinner dot --title "Updating flake inputs..." -- nix flake update
    @just success "Flake update complete"

# Refresh README.md from remote repository
[group('utility')]
refresh-readme:
    @just header "📄 Refresh README"
    @just info "Pulling latest README.md from remote..."
    @gum spin --spinner dot --title "Fetching from origin..." -- git fetch origin
    @git checkout origin/main -- README.md
    @just success "README.md refreshed from remote repository"

# Restore README.md from current commit
[group('utility')]
restore-readme:
    @just header "📄 Restore README"
    @just info "Restoring README.md from current commit..."
    @git restore README.md
    @just success "README.md restored from current commit"

# Set password for a user (hashed and encrypted with agenix)
[group('utility')]
user-password user:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -d "users/{{ user }}" ]; then
        just error "users/{{ user }} directory does not exist"
        exit 1
    fi
    just header "🔐 Set User Password"
    just info "Setting password for user: {{ user }}"
    just warn "Password will be hashed and encrypted with agenix"
    echo ""
    PASSWORD=$(gum input --password --placeholder "Enter password for {{ user }}")
    CONFIRM=$(gum input --password --placeholder "Confirm password")
    if [ "$PASSWORD" != "$CONFIRM" ]; then
        just error "Passwords do not match"
        exit 1
    fi
    HASHED=$(echo "$PASSWORD" | mkpasswd -m sha-512 --stdin)
    echo "$HASHED" > /tmp/user-password-{{ user }}.txt
    just info "Password hashed successfully"
    if [ -f "users/{{ user }}/password.age" ]; then
        rm -f "users/{{ user }}/password.age"
    fi
    just info "Encrypting with agenix..."
    agenix edit -i /tmp/user-password-{{ user }}.txt users/{{ user }}/password.age
    rm -f /tmp/user-password-{{ user }}.txt
    just info "Rekeying secrets..."
    agenix rekey -a
    just success "Password set for {{ user }}"
    echo ""
    gum style --foreground 229 "Don't forget to commit the changes:"
    gum style --foreground 245 "  git add users/{{ user }}/password.age secrets/"
    gum style --foreground 245 "  git commit -m 'chore(users): update password for {{ user }}'"

# =============================================================================
# Private Variant Commands (implementation details)
# =============================================================================

# Local NixOS dry-build
[private]
local-check:
    @just header "🧪 Local Check"
    @just info "Dry-building NixOS configuration for $(hostname)..."
    @nixos-rebuild dry-build --flake .#$(hostname)
    @just success "Check complete for $(hostname)"

# Darwin dry-build
[private]
darwin-check:
    @just header "🧪 Darwin Check"
    @just info "Dry-building darwin configuration for $(hostname)..."
    @nix build .#darwinConfigurations.$(hostname).system --dry-run
    @just success "Check complete for $(hostname)"

# Remote NixOS dry-build
[private]
remote-check host:
    @just header "🧪 Remote Check"
    @just info "Dry-building configuration for {{ host }}..."
    @nixos-rebuild dry-build --flake .#{{ host }}
    @just success "Check complete for {{ host }}"

# Local NixOS deploy
[private]
local-deploy:
    @just header "🐧 Local Deploy"
    @just info "Deploying NixOS configuration for $(hostname)..."
    @sudo nixos-rebuild switch --flake .#$(hostname)
    @just success "Deploy complete for $(hostname)"

# Darwin deploy
[private]
darwin-deploy:
    @just header "🍎 Darwin Deploy"
    @just info "Deploying darwin configuration for $(hostname)..."
    @sudo --preserve-env=SSH_AUTH_SOCK darwin-rebuild switch --flake .#$(hostname)
    @just success "Deploy complete for $(hostname)"

# Remote NixOS deploy
[private]
remote-deploy host:
    #!/usr/bin/env bash
    set -euo pipefail
    just header "🖥️  Remote Deploy"
    just info "Deploying to {{ host }}.meskill.farm..."
    export NIX_SSHOPTS="-o SetEnv=BYPASS_LOGIN_HUB=true"
    nixos-rebuild --sudo --target-host {{ host }}.meskill.farm switch --flake .#{{ host }} --accept-flake-config
    just success "Deploy complete for {{ host }}"

# Local NixOS build (no switch)
[private]
local-build:
    @just header "🔨 Local Build"
    @just info "Building NixOS configuration for $(hostname)..."
    @nixos-rebuild build --flake .#$(hostname)
    @just success "Build complete for $(hostname)"

# Darwin build (no switch)
[private]
darwin-build:
    @just header "🔨 Darwin Build"
    @just info "Building darwin configuration for $(hostname)..."
    @nix build .#darwinConfigurations.$(hostname).system
    @just success "Build complete for $(hostname)"

# Remote NixOS build (no switch)
[private]
remote-build host:
    #!/usr/bin/env bash
    set -euo pipefail
    just header "🔨 Remote Build"
    just info "Building configuration for {{ host }}..."
    export NIX_SSHOPTS="-o SetEnv=BYPASS_LOGIN_HUB=true"
    nixos-rebuild --sudo --target-host {{ host }}.meskill.farm build --flake .#{{ host }} --accept-flake-config
    just success "Build complete for {{ host }}"
