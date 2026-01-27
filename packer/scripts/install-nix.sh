#!/bin/bash
set -euo pipefail

echo "=== Installing Nix (Determinate Systems) ==="

if command -v nix &> /dev/null; then
    echo "Nix already installed:"
    nix --version
    exit 0
fi

curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
    sh -s -- install --no-confirm

echo "=== Sourcing Nix environment ==="
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "=== Configuring shell profiles ==="
NIX_PROFILE_LINE='[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'

for profile in ~/.zshrc ~/.bashrc ~/.bash_profile; do
    if [ -f "$profile" ]; then
        if ! grep -q "nix-daemon.sh" "$profile" 2>/dev/null; then
            echo "$NIX_PROFILE_LINE" >> "$profile"
            echo "Added Nix to $profile"
        fi
    fi
done

echo "=== Verifying installation ==="
nix --version
echo "Nix store: $(nix path-info --store-dir)"

echo "=== Nix installation complete ==="
