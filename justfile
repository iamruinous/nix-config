# justfile for nix-config
# Run `just` to see available recipes

# Default recipe - show help
default:
    @just --list

# Colors and styles (gum-based)
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

# Update all flake inputs
update-flake:
    @just header "🔄 Update Flake"
    @gum spin --spinner dot --title "Updating flake inputs..." -- nix flake update
    @just success "Flake update complete"

# Install Nix package manager
install-nix:
    @just header "📦 Install Nix"
    @just info "Installing Nix package manager..."
    @sudo curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
    @just success "Nix installation complete"

# Install nix-darwin (macOS)
install-nix-darwin:
    @just header "🍎 Install nix-darwin"
    @just info "Installing nix-darwin for $(hostname)..."
    @nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake .#$(hostname)
    @just success "nix-darwin installation complete"

# Rebuild Darwin configuration for current host
darwin-rebuild:
    @just header "🍎 Darwin Rebuild"
    @just info "Rebuilding darwin configuration for $(hostname)..."
    @sudo --preserve-env=SSH_AUTH_SOCK darwin-rebuild switch --flake .#$(hostname)
    @just success "Darwin rebuild complete"

# Rebuild NixOS configuration for current host
linux-rebuild:
    @just header "🐧 Linux Rebuild"
    @just info "Rebuilding NixOS configuration for $(hostname)..."
    @sudo nixos-rebuild switch --flake .#$(hostname)
    @just success "Linux rebuild complete"

# Deploy configuration to host (auto-detects local vs remote, Darwin vs Linux)
deploy host:
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
            just darwin-rebuild
        else
            just linux-rebuild
        fi
    elif [ "$is_darwin_host" = "true" ]; then
        # Darwin hosts don't support remote-rebuild
        just error "Darwin hosts don't support remote deployment. Run 'just darwin-rebuild' on {{ host }} directly."
        exit 1
    else
        # Remote NixOS deployment
        just remote-rebuild {{ host }}
    fi

# Dry-build configuration for current host
dry-build:
    @just header "🧪 Dry Build"
    @just info "Dry-building configuration for $(hostname)..."
    @nixos-rebuild dry-build --flake .#$(hostname)
    @just success "Dry-build complete for $(hostname)"

# Rebuild configuration on remote host
remote-rebuild remotehost:
    #!/usr/bin/env bash
    set -euo pipefail
    just header "🖥️  Remote Rebuild"
    just info "Rebuilding {{ remotehost }}.meskill.farm..."
    export NIX_SSHOPTS="-o SetEnv=BYPASS_LOGIN_HUB=true"
    nixos-rebuild --sudo --target-host {{ remotehost }}.meskill.farm switch --flake .#{{ remotehost }} --accept-flake-config
    just success "Remote rebuild complete for {{ remotehost }}"

# Dry-build configuration for remote host
remote-dry-build remotehost:
    @just header "🧪 Remote Dry Build"
    @just info "Dry-building configuration for {{ remotehost }}..."
    @nixos-rebuild dry-build --flake .#{{ remotehost }}
    @just success "Dry-build complete for {{ remotehost }}"

# Refresh README.md from remote repository
refresh-readme:
    @just header "📄 Refresh README"
    @just info "Pulling latest README.md from remote..."
    @gum spin --spinner dot --title "Fetching from origin..." -- git fetch origin
    @git checkout origin/main -- README.md
    @just success "README.md refreshed from remote repository"

# Restore README.md from current commit
restore-readme:
    @just header "📄 Restore README"
    @just info "Restoring README.md from current commit..."
    @git restore README.md
    @just success "README.md restored from current commit"

# Bootstrap a fresh macOS system
bootstrap-mac: install-nix install-nix-darwin

# Build Raspberry Pi SD image on armistice
pi-sdimage pihost:
    #!/usr/bin/env bash
    set -euo pipefail
    just header "🥧 Build Raspberry Pi SD Image"
    just info "Building SD image for {{ pihost }} on armistice..."
    export NIX_SSHOPTS="-o SetEnv=BYPASS_LOGIN_HUB=true"
    nix build .#nixosConfigurations.{{ pihost }}.config.system.build.sdImage \
        --builders "ssh://armistice.meskill.farm aarch64-linux - 12 1 benchmark,big-parallel,kvm" \
        --max-jobs 0 \
        --cores 0 \
        --log-format bar-with-logs \
        -o result-{{ pihost }}-sdimage
    just success "SD image built: result-{{ pihost }}-sdimage/"
    @echo ""
    @gum style --foreground 229 "To flash to SD card:"
    @gum style --foreground 245 "  just pi-flash {{ pihost }} /dev/sdX"

# Flash Raspberry Pi SD image to device
pi-flash pihost device:
    #!/usr/bin/env bash
    set -euo pipefail
    just header "🥧 Flash Raspberry Pi SD Card"
    if [ ! -d "result-{{ pihost }}-sdimage" ]; then
        just error "result-{{ pihost }}-sdimage not found. Run 'just pi-sdimage {{ pihost }}' first."
        exit 1
    fi
    if [ ! -b "{{ device }}" ]; then
        just error "{{ device }} is not a block device"
        exit 1
    fi
    just warn "This will erase all data on {{ device }}!"
    gum confirm "Flash {{ pihost }} image to {{ device }}?" || exit 1
    just info "Decompressing image..."
    gum spin --spinner dot --title "Decompressing {{ pihost }} image..." -- zstd -d -f result-{{ pihost }}-sdimage/sd-image/*.img.zst -o /tmp/{{ pihost }}.img
    just info "Flashing to {{ device }}..."
    sudo bmaptool copy --nobmap /tmp/{{ pihost }}.img {{ device }}
    sync
    rm -f /tmp/{{ pihost }}.img
    just success "Flash complete! You can safely remove {{ device }}."

# Sanity check - dry-build representative hosts
check:
    @just header "🧪 Sanity Check - Dry Build Representative Hosts"
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
    @gum style --foreground 82 --bold "✓ All sanity checks passed!"

# Set password for a user (hashed and encrypted with agenix)
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
