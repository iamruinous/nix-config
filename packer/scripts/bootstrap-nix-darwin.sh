#!/bin/bash
set -euo pipefail

FLAKE_REF="${1:-}"
HOSTNAME="${2:-}"

if [ -z "$FLAKE_REF" ] || [ -z "$HOSTNAME" ]; then
    echo "Usage: $0 <flake-ref> <hostname>"
    echo "Example: $0 github:iamruinous/nix-config clawdbot-vm"
    exit 1
fi

echo "=== Bootstrapping nix-darwin ==="
echo "Flake: $FLAKE_REF"
echo "Hostname: $HOSTNAME"

if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! command -v nix &> /dev/null; then
    echo "ERROR: Nix not found. Run install-nix.sh first."
    exit 1
fi

echo "=== Moving existing nix.conf to avoid interactive prompt ==="
if [ -f /etc/nix/nix.conf ]; then
    sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-darwin
    echo "Backed up /etc/nix/nix.conf to /etc/nix/nix.conf.before-darwin"
fi

echo "=== Running nix-darwin bootstrap ==="
nix run nix-darwin -- switch --flake "${FLAKE_REF}#${HOSTNAME}" --show-trace

if command -v darwin-rebuild &> /dev/null; then
    echo "=== nix-darwin installed successfully ==="
    darwin-rebuild --version || true
else
    echo "=== Verifying installation via nix profile ==="
    ls -la /run/current-system/sw/bin/darwin-rebuild 2>/dev/null || echo "darwin-rebuild not in expected location"
fi

echo "=== nix-darwin bootstrap complete ==="
