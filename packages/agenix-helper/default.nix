{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "agenix-helper";
  version = "0.1.0";
  dontUnpack = true;

  propagatedBuildInputs = [
    pkgs.rage
    pkgs.coreutils
  ];

  passthru.shellPath = "/bin/agenix-helper";
  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin

    cat > $out/bin/agenix-helper << 'EOF'
#!/usr/bin/env bash
# Helper script for unlocking/locking age identity
# Based on https://github.com/suderman/nixos/blob/main/packages/agenix/agenix.sh

set -euo pipefail

AGE_IDENTITY_FILE="''${AGE_IDENTITY_FILE:-/tmp/id_age}"
AGE_IDENTITY_ENCRYPTED="''${AGE_IDENTITY_ENCRYPTED:-secrets/id_age.age}"
AGE_IDENTITY_BACKUP="''${AGE_IDENTITY_BACKUP:-/tmp/id_age_}"

agenix_unlock() {
  local quiet="''${1:-}"

  # If quiet mode and the decrypted age identity already exists, skip
  if [[ "$quiet" == "quiet" ]]; then
    [[ -f "$AGE_IDENTITY_FILE" ]] && return 0
    # In quiet mode, if not already unlocked, silently fail
    # User needs to manually unlock with: agenix-helper unlock
    return 1
  fi

  # Check if encrypted identity exists
  if [[ ! -f "$AGE_IDENTITY_ENCRYPTED" ]]; then
    echo "Error: $AGE_IDENTITY_ENCRYPTED not found"
    return 1
  fi

  # Optionally accept an age identity through standard input
  local id=""
  if [[ ! -t 0 ]]; then
    id="$(cat)"
  fi

  # Attempt to decrypt age identity using passphrase (interactive only)
  if [[ -z "$id" ]]; then
    # Check if we can use 1Password CLI for pinentry
    if command -v op &>/dev/null && command -v pinentry-1password &>/dev/null && [[ -n "''${OP_PIN_ITEM:-}" ]]; then
      # Use pinentry-1password for passphrase retrieval
      export PINENTRY_PROGRAM="pinentry-1password"
      id="$(${pkgs.rage}/bin/rage -d <"$AGE_IDENTITY_ENCRYPTED" 2>&1 || true)"
      unset PINENTRY_PROGRAM
    else
      # Fall back to standard interactive passphrase prompt
      id="$(${pkgs.rage}/bin/rage -d <"$AGE_IDENTITY_ENCRYPTED" 2>&1 || true)"
    fi

    if [[ -z "$id" ]] || [[ "$id" =~ "incorrect" ]]; then
      echo "Error: Failed to decrypt age identity (incorrect passphrase?)"
      return 1
    fi
  fi

  # Backup any existing identity
  if [[ -f "$AGE_IDENTITY_FILE" ]]; then
    mv "$AGE_IDENTITY_FILE" "$AGE_IDENTITY_BACKUP"
  fi
  touch "$AGE_IDENTITY_BACKUP" 2>/dev/null || true

  # Write decrypted age identity to tmp directory
  echo "$id" >"$AGE_IDENTITY_FILE"
  chmod 600 "$AGE_IDENTITY_FILE" "$AGE_IDENTITY_BACKUP" 2>/dev/null || true

  # Notify user unless quiet
  if [[ "$quiet" != "quiet" ]]; then
    echo "🔓 Age identity unlocked at $AGE_IDENTITY_FILE"
  fi
}

agenix_lock() {
  local quiet="''${1:-}"

  # Remove the decrypted identity files
  if [[ -f "$AGE_IDENTITY_FILE" ]] || [[ -f "$AGE_IDENTITY_BACKUP" ]]; then
    rm -f "$AGE_IDENTITY_FILE" "$AGE_IDENTITY_BACKUP"

    if [[ "$quiet" != "quiet" ]]; then
      echo "🔒 Age identity locked (removed $AGE_IDENTITY_FILE)"
    fi
  fi
}

agenix_status() {
  if [[ -f "$AGE_IDENTITY_FILE" ]]; then
    echo "🔓 Age identity is unlocked at $AGE_IDENTITY_FILE"
    return 0
  else
    echo "🔒 Age identity is locked"
    return 1
  fi
}

# Main command routing
case "''${1:-status}" in
  unlock|u)
    agenix_unlock "''${2:-}"
    ;;
  lock|l)
    agenix_lock "''${2:-}"
    ;;
  status|s)
    agenix_status
    ;;
  *)
    echo "Usage: $0 {unlock|lock|status} [quiet]"
    echo ""
    echo "Commands:"
    echo "  unlock, u [quiet]  - Decrypt age identity to $AGE_IDENTITY_FILE"
    echo "  lock, l [quiet]    - Remove decrypted age identity"
    echo "  status, s          - Check if age identity is unlocked"
    echo ""
    echo "Environment variables:"
    echo "  AGE_IDENTITY_FILE      - Path to decrypted identity (default: /tmp/id_age)"
    echo "  AGE_IDENTITY_ENCRYPTED - Path to encrypted identity (default: secrets/id_age.age)"
    echo "  OP_PIN_ITEM            - 1Password item reference for passphrase (optional)"
    echo ""
    echo "1Password integration:"
    echo "  If op CLI and pinentry-1password are available, set OP_PIN_ITEM to use"
    echo "  1Password for passphrase retrieval: export OP_PIN_ITEM='op://vault/item/field'"
    exit 1
    ;;
esac
EOF

    chmod +x $out/bin/agenix-helper
  '';

  installPhase = ''
    # No installation steps needed beyond what's done in buildPhase
    true
  '';

  meta = with pkgs.lib; {
    description = "Helper utilities for working with agenix encrypted secrets";
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "agenix-helper";
    platforms = platforms.unix;
  };
}
