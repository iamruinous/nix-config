# justfile for nix-config
# Run `just` to see available recipes

# Default recipe - show banner + help
default:
    @just n0-banner
    @just --list

[private]
n0-banner:
    #!/usr/bin/env bash
    # N0FRILLS gradient banner using figlet font
    FONT_URL="https://forge.meskill.farm/RUiNAGE/N0FRILLS/raw/branch/main/font/N0FRILLS.flf"
    FONT_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/n0frills/N0FRILLS.flf"
    
    # Cache the font locally
    if [ ! -f "$FONT_CACHE" ]; then
        mkdir -p "$(dirname "$FONT_CACHE")"
        curl -sL "$FONT_URL" -o "$FONT_CACHE" 2>/dev/null || true
    fi
    
    echo ""
    if [ -f "$FONT_CACHE" ] && command -v figlet &>/dev/null; then
        # Generate banner with gradient (white -> magenta)
        n=0
        figlet -f "$FONT_CACHE" "RUiNiX" | while IFS= read -r line; do
            n=$((n + 1))
            case $n in
                1) gum style --foreground "#ffffff" "$line" ;;
                2) gum style --foreground "#eeaadd" "$line" ;;
                3) gum style --foreground "#dd77cc" "$line" ;;
                4) gum style --foreground "#d75fd7" "$line" ;;
                *) gum style --foreground "#d75fd7" "$line" ;;
            esac
        done
    else
        # Fallback if figlet unavailable
        gum style --foreground "#d75fd7" --bold "RUiNiX"
    fi
    echo ""

# =============================================================================
# N0FRILLS Output Helpers
# =============================================================================

[private]
n0-header title:
    @echo ""
    @gum style --foreground "#d75fd7" --bold "{{ title }}"

[private]
n0-info msg:
    @echo "    {{ msg }}"

[private]
n0-ok msg="Done.":
    @gum style --foreground "#5fd7d7" "[+] {{ msg }}"

[private]
n0-warn msg:
    @gum style --foreground "#ffaf00" "[!] {{ msg }}"

[private]
n0-error msg:
    @gum style --foreground "#af0000" "[!] {{ msg }}"

[private]
n0-action msg:
    @gum style --foreground "#8a8a8a" "[>] {{ msg }}"

# =============================================================================
# HOST
# =============================================================================

# Verify configuration builds (dry-build)
[group('host')]
check host=`hostname`:
    #!/usr/bin/env bash
    set -euo pipefail
    current_host=$(hostname)
    os_type=$(uname -s)
    
    is_darwin_host=false
    [ -f "hosts/{{ host }}/darwin-configuration.nix" ] && is_darwin_host=true
    
    if [ "{{ host }}" = "$current_host" ]; then
        if [ "$os_type" = "Darwin" ]; then
            just darwin-check
        else
            just local-check
        fi
    elif [ "$is_darwin_host" = "true" ]; then
        just n0-header "CHECK"
        just n0-action "{{ host }} (darwin)"
        nix build .#darwinConfigurations.{{ host }}.system --dry-run
        just n0-ok
    else
        just remote-check {{ host }}
    fi

# Deploy configuration to host
[group('host')]
deploy host=`hostname`:
    #!/usr/bin/env bash
    set -euo pipefail
    current_host=$(hostname)
    os_type=$(uname -s)
    
    is_darwin_host=false
    [ -f "hosts/{{ host }}/darwin-configuration.nix" ] && is_darwin_host=true
    
    if [ "{{ host }}" = "$current_host" ]; then
        if [ "$os_type" = "Darwin" ]; then
            just darwin-deploy
        else
            just local-deploy
        fi
    elif [ "$is_darwin_host" = "true" ]; then
        just n0-error "Darwin hosts: run 'just deploy' locally"
        exit 1
    else
        just remote-deploy {{ host }}
    fi

# Build configuration without switching
[group('host')]
build host=`hostname`:
    #!/usr/bin/env bash
    set -euo pipefail
    current_host=$(hostname)
    os_type=$(uname -s)
    
    is_darwin_host=false
    [ -f "hosts/{{ host }}/darwin-configuration.nix" ] && is_darwin_host=true
    
    if [ "{{ host }}" = "$current_host" ]; then
        if [ "$os_type" = "Darwin" ]; then
            just darwin-build
        else
            just local-build
        fi
    elif [ "$is_darwin_host" = "true" ]; then
        just n0-header "BUILD"
        just n0-action "{{ host }} (darwin)"
        nix build .#darwinConfigurations.{{ host }}.system
        just n0-ok
    else
        just remote-build {{ host }}
    fi

# Bootstrap host with nixos-anywhere
[group('host')]
bringup host sshpass:
    #!/usr/bin/env bash
    set -euo pipefail
    just n0-header "BRINGUP"
    just n0-warn "This will ERASE {{ host }} and install NixOS"
    gum confirm "Proceed?" || exit 1
    just n0-action "{{ host }}"
    env SSHPASS="{{ sshpass }}" nix run github:nix-community/nixos-anywhere -- \
        --flake .#{{ host }} \
        --target-host nixos@{{ host }}.meskill.farm \
        --env-password
    just n0-ok

# Install Nix and nix-darwin (macOS)
[group('host')]
install:
    #!/usr/bin/env bash
    set -euo pipefail
    os_type=$(uname -s)
    
    just n0-header "INSTALL"
    
    if [ "$os_type" = "Darwin" ]; then
        just n0-action "lix"
        curl -sSf -L https://install.lix.systems/lix | sh -s -- install
        just n0-action "nix-darwin"
        nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake .#$(hostname)
    else
        just n0-action "nix"
        curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
    fi
    just n0-ok

# =============================================================================
# VALIDATE
# =============================================================================

# Dry-build representative hosts
[group('validate')]
canary:
    #!/usr/bin/env bash
    set -euo pipefail
    just n0-header "CANARY"
    
    hosts=(
        "chassis:nixos:desktop"
        "framework:nixos:laptop"
        "monolith:nixos:server"
        "jbookpro:darwin:workstation"
        "rp500:nixos:pi5"
        "rpc-4-echo:nixos:pi4"
    )
    
    for entry in "${hosts[@]}"; do
        IFS=':' read -r host type label <<< "$entry"
        just n0-action "$host ($label)"
        if [ "$type" = "darwin" ]; then
            nix build .#darwinConfigurations.$host.system --dry-run 2>/dev/null
        else
            nix build .#nixosConfigurations.$host.config.system.build.toplevel --dry-run 2>/dev/null
        fi
    done
    
    echo ""
    gum style --foreground "#5fd7d7" --bold "[+] All canary checks passed"

# =============================================================================
# SECRETS
# =============================================================================

# Unlock agenix identity
[group('secrets')]
unlock:
    @just n0-header "UNLOCK"
    @agenix-helper unlock
    @just n0-ok

# View encrypted secret
[group('secrets')]
peek secret:
    @just n0-header "PEEK"
    @agenix view {{ secret }}

# Edit encrypted secret
[group('secrets')]
encrypt secret:
    @just n0-header "ENCRYPT"
    @agenix edit {{ secret }}

# Re-encrypt all secrets
[group('secrets')]
rekey:
    @just n0-header "REKEY"
    @just n0-action "generate"
    @agenix generate -a
    @just n0-action "rekey"
    @agenix rekey -a
    @just n0-ok
    @echo ""
    @gum style --foreground "#8a8a8a" "Commit: git add secrets/"

# =============================================================================
# PI
# =============================================================================

# Build Raspberry Pi SD image
[group('pi')]
sd-image host:
    #!/usr/bin/env bash
    set -euo pipefail
    just n0-header "SD-IMAGE"
    just n0-action "{{ host }} -> armistice"
    export NIX_SSHOPTS="-o SetEnv=BYPASS_LOGIN_HUB=true"
    nix build .#nixosConfigurations.{{ host }}.config.system.build.sdImage \
        --builders "ssh://armistice.meskill.farm aarch64-linux - 12 1 benchmark,big-parallel,kvm" \
        --max-jobs 0 \
        --cores 0 \
        --log-format bar-with-logs \
        -o result-{{ host }}-sdimage
    just n0-ok "result-{{ host }}-sdimage/"
    echo ""
    gum style --foreground "#8a8a8a" "Flash: just sd-flash {{ host }} /dev/sdX"

# Flash SD image to device
[group('pi')]
sd-flash host device:
    #!/usr/bin/env bash
    set -euo pipefail
    just n0-header "SD-FLASH"
    
    [ ! -d "result-{{ host }}-sdimage" ] && { just n0-error "Run 'just sd-image {{ host }}' first"; exit 1; }
    [ ! -b "{{ device }}" ] && { just n0-error "{{ device }} not a block device"; exit 1; }
    
    just n0-warn "Will erase {{ device }}"
    gum confirm "Proceed?" || exit 1
    
    just n0-action "decompress"
    gum spin --spinner dot --title "Decompressing..." -- zstd -d -f result-{{ host }}-sdimage/sd-image/*.img.zst -o /tmp/{{ host }}.img
    
    just n0-action "flash -> {{ device }}"
    sudo bmaptool copy --nobmap /tmp/{{ host }}.img {{ device }}
    sync
    rm -f /tmp/{{ host }}.img
    just n0-ok "Safe to remove {{ device }}"

# =============================================================================
# UTILITY
# =============================================================================

# Update all flake inputs
[group('utility')]
update-flake:
    @just n0-header "UPDATE"
    @gum spin --spinner dot --title "Updating..." -- nix flake update
    @just n0-ok

# Refresh README.md from remote
[group('utility')]
refresh-readme:
    @just n0-header "REFRESH-README"
    @gum spin --spinner dot --title "Fetching..." -- git fetch origin
    @git checkout origin/main -- README.md
    @just n0-ok

# Restore README.md from commit
[group('utility')]
restore-readme:
    @just n0-header "RESTORE-README"
    @git restore README.md
    @just n0-ok

# Set user password (hashed + encrypted)
[group('utility')]
user-password user:
    #!/usr/bin/env bash
    set -euo pipefail
    [ ! -d "users/{{ user }}" ] && { just n0-error "users/{{ user }} not found"; exit 1; }
    
    just n0-header "USER-PASSWORD"
    just n0-info "{{ user }}"
    
    PASSWORD=$(gum input --password --placeholder "password")
    CONFIRM=$(gum input --password --placeholder "confirm")
    [ "$PASSWORD" != "$CONFIRM" ] && { just n0-error "Passwords don't match"; exit 1; }
    
    HASHED=$(echo "$PASSWORD" | mkpasswd -m sha-512 --stdin)
    echo "$HASHED" > /tmp/user-password-{{ user }}.txt
    
    [ -f "users/{{ user }}/password.age" ] && rm -f "users/{{ user }}/password.age"
    
    just n0-action "encrypt"
    agenix edit -i /tmp/user-password-{{ user }}.txt users/{{ user }}/password.age
    rm -f /tmp/user-password-{{ user }}.txt
    
    just n0-action "rekey"
    agenix rekey -a
    just n0-ok
    echo ""
    gum style --foreground "#8a8a8a" "Commit: git add users/{{ user }}/password.age secrets/"

# =============================================================================
# PRIVATE IMPLEMENTATIONS
# =============================================================================

[private]
local-check:
    @just n0-header "CHECK"
    @just n0-action "$(hostname) (nixos)"
    @nixos-rebuild dry-build --flake .#$(hostname)
    @just n0-ok

[private]
darwin-check:
    @just n0-header "CHECK"
    @just n0-action "$(hostname) (darwin)"
    @nix build .#darwinConfigurations.$(hostname).system --dry-run
    @just n0-ok

[private]
remote-check host:
    @just n0-header "CHECK"
    @just n0-action "{{ host }} (remote)"
    @nixos-rebuild dry-build --flake .#{{ host }}
    @just n0-ok

[private]
local-deploy:
    @just n0-header "DEPLOY"
    @just n0-action "$(hostname) (nixos)"
    @sudo nixos-rebuild switch --flake .#$(hostname)
    @just n0-ok

[private]
darwin-deploy:
    @just n0-header "DEPLOY"
    @just n0-action "$(hostname) (darwin)"
    @sudo --preserve-env=SSH_AUTH_SOCK darwin-rebuild switch --flake .#$(hostname)
    @just n0-ok

[private]
remote-deploy host:
    #!/usr/bin/env bash
    set -euo pipefail
    just n0-header "DEPLOY"
    just n0-action "{{ host }} (remote)"
    export NIX_SSHOPTS="-o SetEnv=BYPASS_LOGIN_HUB=true"
    nixos-rebuild --sudo --target-host {{ host }}.meskill.farm switch --flake .#{{ host }} --accept-flake-config
    just n0-ok

[private]
local-build:
    @just n0-header "BUILD"
    @just n0-action "$(hostname) (nixos)"
    @nixos-rebuild build --flake .#$(hostname)
    @just n0-ok

[private]
darwin-build:
    @just n0-header "BUILD"
    @just n0-action "$(hostname) (darwin)"
    @nix build .#darwinConfigurations.$(hostname).system
    @just n0-ok

[private]
remote-build host:
    #!/usr/bin/env bash
    set -euo pipefail
    just n0-header "BUILD"
    just n0-action "{{ host }} (remote)"
    export NIX_SSHOPTS="-o SetEnv=BYPASS_LOGIN_HUB=true"
    nixos-rebuild --sudo --target-host {{ host }}.meskill.farm build --flake .#{{ host }} --accept-flake-config
    just n0-ok
