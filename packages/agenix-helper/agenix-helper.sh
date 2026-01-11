#!/usr/bin/env bash
# Helper script for unlocking/locking age identity
# Based on https://github.com/suderman/nixos/blob/main/packages/agenix/agenix.sh

set -euo pipefail

GUM="@gum@/bin/gum"

# Default to XDG state directory for better systemd service compatibility
AGE_IDENTITY_DIR="${AGE_IDENTITY_DIR:-$HOME/.local/state/agenix-helper}"
AGE_IDENTITY_FILE="${AGE_IDENTITY_FILE:-$AGE_IDENTITY_DIR/host_id_age}"
AGE_IDENTITY_ENCRYPTED="${AGE_IDENTITY_ENCRYPTED:-secrets/id_age.age}"
AGE_IDENTITY_BACKUP="${AGE_IDENTITY_BACKUP:-$AGE_IDENTITY_DIR/host_id_age_}"

# User-specific identity for home-manager agenix
AGE_USER_IDENTITY_FILE="${AGE_USER_IDENTITY_FILE:-$HOME/.config/age/user_id_age}"
AGE_USER_IDENTITY_ENCRYPTED="${AGE_USER_IDENTITY_ENCRYPTED:-users/$USER/id_age.age}"

log_success() { $GUM log --level info "$1"; }
log_warn() { $GUM log --level warn "$1"; }
log_error() { $GUM log --level error "$1"; }

agenix_unlock() {
  local quiet="${1:-}"

  # If quiet mode and the decrypted age identity already exists, skip
  if [[ "$quiet" == "quiet" ]]; then
    [[ -f "$AGE_IDENTITY_FILE" ]] && return 0
    # In quiet mode, if not already unlocked, silently fail
    # User needs to manually unlock with: agenix-helper unlock
    return 1
  fi

  # Check if already unlocked (idempotent behavior)
  if [[ -f "$AGE_IDENTITY_FILE" ]] && [[ -L /tmp/host_id_age ]]; then
    $GUM style --foreground 82 "✓ Already unlocked at $AGE_IDENTITY_FILE"
    $GUM style --foreground 245 "  Symlinked to /tmp/host_id_age for agenix-rekey"
    if [[ -f "$AGE_USER_IDENTITY_FILE" ]]; then
      $GUM style --foreground 82 "✓ User identity already unlocked at $AGE_USER_IDENTITY_FILE"
    fi
    return 0
  fi

  if [[ ! -f "$AGE_IDENTITY_ENCRYPTED" ]]; then
    log_error "$AGE_IDENTITY_ENCRYPTED not found"
    return 1
  fi

  # Optionally accept an age identity through standard input
  local id=""
  if [[ ! -t 0 ]]; then
    id="$(cat)"
  fi

  if [[ -z "$id" ]]; then
    if command -v op &>/dev/null && [[ -n "${OP_PIN_ITEM:-}" ]]; then
      local passphrase=""
      passphrase="$(op read "$OP_PIN_ITEM" 2>/dev/null || true)"
      if [[ -n "$passphrase" ]]; then
        id="$(printf '%s' "$passphrase" | @rage@/bin/rage -d -i - "$AGE_IDENTITY_ENCRYPTED" 2>/dev/null || true)"
      fi
    fi

    if [[ -z "$id" ]] || [[ "$id" =~ "error" ]]; then
      $GUM style --foreground 255 --border rounded --border-foreground 208 --padding "1 2" --margin "1 0" \
        "⚠️  Unlocking agenix identities"
      $GUM style --foreground 245 --italic "Enter passphrase for $AGE_IDENTITY_ENCRYPTED"
      id="$(@rage@/bin/rage -d "$AGE_IDENTITY_ENCRYPTED" 2>&1 || true)"
    fi

    if [[ -z "$id" ]] || [[ "$id" =~ "incorrect" ]] || [[ "$id" =~ "error" ]]; then
      log_error "Failed to decrypt age identity (incorrect passphrase?)"
      return 1
    fi
  fi

  # Backup any existing identity
  if [[ -f "$AGE_IDENTITY_FILE" ]]; then
    mv "$AGE_IDENTITY_FILE" "$AGE_IDENTITY_BACKUP"
  fi

  mkdir -p "$AGE_IDENTITY_DIR"
  chmod 700 "$AGE_IDENTITY_DIR"
  touch "$AGE_IDENTITY_BACKUP" 2>/dev/null || true

  echo "$id" >"$AGE_IDENTITY_FILE"
  chmod 600 "$AGE_IDENTITY_FILE" "$AGE_IDENTITY_BACKUP" 2>/dev/null || true

  # Create /tmp symlinks for agenix-rekey compatibility
  # agenix-rekey evaluates ALL host configs, so we need static paths that don't vary by user
  ln -sf "$AGE_IDENTITY_FILE" /tmp/host_id_age
  ln -sf "$AGE_IDENTITY_BACKUP" /tmp/host_id_age_

  if [[ "$quiet" != "quiet" ]]; then
    $GUM style --foreground 82 "🔓 Host identity unlocked at $AGE_IDENTITY_FILE"
    $GUM style --foreground 245 "   Symlinked to /tmp/host_id_age for agenix-rekey"
  fi

  # Decrypt and deploy user-specific identity for home-manager agenix
  if [[ -f "$AGE_USER_IDENTITY_ENCRYPTED" ]]; then
    local user_id=""
    
    user_id="$(@rage@/bin/rage -d -i "$AGE_IDENTITY_FILE" "$AGE_USER_IDENTITY_ENCRYPTED" 2>/dev/null || true)"

    if [[ -n "$user_id" ]] && [[ ! "$user_id" =~ "error" ]]; then
      mkdir -p "$(dirname "$AGE_USER_IDENTITY_FILE")"
      printf '%s\n' "$user_id" >"$AGE_USER_IDENTITY_FILE"
      chmod 600 "$AGE_USER_IDENTITY_FILE"

      if [[ "$quiet" != "quiet" ]]; then
        $GUM style --foreground 82 "🔓 User identity unlocked at $AGE_USER_IDENTITY_FILE"
      fi
    elif [[ "$quiet" != "quiet" ]]; then
      log_warn "Could not decrypt user identity at $AGE_USER_IDENTITY_ENCRYPTED"
    fi
  fi
}

agenix_lock() {
  local quiet="${1:-}"
  local locked_any=false

  if [[ -f "$AGE_IDENTITY_FILE" ]] || [[ -f "$AGE_IDENTITY_BACKUP" ]]; then
    rm -f "$AGE_IDENTITY_FILE" "$AGE_IDENTITY_BACKUP"
    rm -f /tmp/host_id_age /tmp/host_id_age_
    locked_any=true
  fi

  if [[ -f "$AGE_USER_IDENTITY_FILE" ]]; then
    rm -f "$AGE_USER_IDENTITY_FILE"
    locked_any=true
  fi

  if [[ "$quiet" != "quiet" ]] && [[ "$locked_any" == "true" ]]; then
    $GUM style --foreground 255 --border rounded --border-foreground 196 --padding "1 2" --margin "1 0" \
      "🔒 Agenix identities locked and removed"
  fi
}

agenix_status() {
  local status=0

  if [[ -f "$AGE_IDENTITY_FILE" ]]; then
    log_success "Age identity is unlocked at $AGE_IDENTITY_FILE"
  else
    log_warn "Age identity is locked"
    status=1
  fi

  if [[ -f "$AGE_USER_IDENTITY_FILE" ]]; then
    log_success "User identity is unlocked at $AGE_USER_IDENTITY_FILE"
  else
    log_warn "User identity is locked"
  fi

  return $status
}

# Main command routing
case "${1:-status}" in
  unlock|u)
    agenix_unlock "${2:-}"
    ;;
  lock|l)
    agenix_lock "${2:-}"
    ;;
  status|s)
    agenix_status
    ;;
  *)
    echo "Usage: $0 {unlock|lock|status} [quiet]"
    echo ""
    echo "Commands:"
    echo "  unlock, u [quiet]  - Decrypt age identities"
    echo "  lock, l [quiet]    - Remove decrypted age identities"
    echo "  status, s          - Check if age identities are unlocked"
    echo ""
    echo "Environment variables:"
    echo "  AGE_IDENTITY_DIR            - Directory for identity files (default: ~/.local/state/agenix-helper)"
    echo "  AGE_IDENTITY_FILE           - Path to decrypted host identity (default: \$AGE_IDENTITY_DIR/host_id_age)"
    echo "  AGE_IDENTITY_ENCRYPTED      - Path to encrypted host identity (default: secrets/id_age.age)"
    echo "  AGE_USER_IDENTITY_FILE      - Path to decrypted user identity (default: ~/.config/age/user_id_age)"
    echo "  AGE_USER_IDENTITY_ENCRYPTED - Path to encrypted user identity (default: users/\$USER/id_age.age)"
    echo "  OP_PIN_ITEM                 - 1Password item reference for passphrase (optional)"
    echo ""
    echo "1Password integration:"
    echo "  If op CLI and pinentry-1password are available, set OP_PIN_ITEM to use"
    echo "  1Password for passphrase retrieval: export OP_PIN_ITEM='op://vault/item/field'"
    exit 1
    ;;
esac
