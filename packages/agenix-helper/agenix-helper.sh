#!/usr/bin/env bash
# Helper script for unlocking/locking age identity
# Based on https://github.com/suderman/nixos/blob/main/packages/agenix/agenix.sh

set -euo pipefail

GUM="@gum@/bin/gum"
RAGE="@rage@/bin/rage"

# Default to XDG state directory for better systemd service compatibility
AGE_IDENTITY_DIR="${AGE_IDENTITY_DIR:-$HOME/.local/state/agenix-helper}"
AGE_IDENTITY_FILE="${AGE_IDENTITY_FILE:-$AGE_IDENTITY_DIR/host_id_age}"
AGE_IDENTITY_ENCRYPTED="${AGE_IDENTITY_ENCRYPTED:-secrets/id_age.age}"
AGE_IDENTITY_BACKUP="${AGE_IDENTITY_BACKUP:-$AGE_IDENTITY_DIR/host_id_age_}"

# User-specific identity for home-manager agenix
AGE_USER_IDENTITY_FILE="${AGE_USER_IDENTITY_FILE:-$HOME/.config/age/user_id_age}"
AGE_USER_IDENTITY_ENCRYPTED="${AGE_USER_IDENTITY_ENCRYPTED:-users/$USER/id_age.age}"

DEBUG="${AGENIX_HELPER_DEBUG:-}"

log_success() { $GUM log --level info "$1"; }
log_warn() { $GUM log --level warn "$1"; }
log_error() { $GUM log --level error "$1"; }
log_debug() {
  if [[ -n "$DEBUG" ]]; then
    $GUM log --level debug "$1"
  fi
}

has_pinentry_tools() {
  local has_op=false
  local has_pinentry=false

  if command -v op &>/dev/null; then
    has_op=true
    log_debug "op CLI found at: $(command -v op)"
  else
    log_debug "op CLI not found"
  fi

  if command -v pinentry-1password &>/dev/null; then
    has_pinentry=true
    log_debug "pinentry-1password found at: $(command -v pinentry-1password)"
  else
    log_debug "pinentry-1password not found"
  fi

  if [[ "$has_op" == "true" ]] && [[ "$has_pinentry" == "true" ]]; then
    log_debug "pinentry tools available"
    return 0
  else
    log_debug "pinentry tools NOT available (op=$has_op, pinentry=$has_pinentry)"
    return 1
  fi
}

run_rage_with_pinentry() {
  local op_secret="$1"
  local encrypted_file="$2"
  local extra_args="${3:-}"

  log_debug "Setting OP_PIN_ITEM=$op_secret for pinentry-1password"
  export OP_PIN_ITEM="$op_secret"
  export PINENTRY_PROGRAM="pinentry-1password"
  log_debug "PINENTRY_PROGRAM set to: $PINENTRY_PROGRAM"

  local result=""
  if [[ -n "$extra_args" ]]; then
    log_debug "Running: $RAGE $extra_args $encrypted_file"
    result="$($RAGE $extra_args "$encrypted_file" 2>&1 || true)"
  else
    log_debug "Running: $RAGE -d $encrypted_file"
    result="$($RAGE -d "$encrypted_file" 2>&1 || true)"
  fi

  unset PINENTRY_PROGRAM
  unset OP_PIN_ITEM

  log_debug "rage output length: ${#result}"
  if [[ ${#result} -lt 200 ]]; then
    log_debug "rage output: $result"
  else
    log_debug "rage output (first 200 chars): ${result:0:200}"
  fi

  echo "$result"
}

agenix_unlock() {
  local quiet="${1:-}"

  if [[ "$quiet" == "quiet" ]]; then
    [[ -f "$AGE_IDENTITY_FILE" ]] && return 0
    return 1
  fi

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

  local id=""
  if [[ ! -t 0 ]]; then
    id="$(cat)"
  fi

  if [[ -z "$id" ]]; then
    log_debug "No identity from stdin, checking pinentry-1password availability..."
    if has_pinentry_tools && [[ -n "${AGENIX_HELPER_OP_HOST_SECRET:-}" ]]; then
      log_debug "Using pinentry-1password for host identity decryption"
      log_debug "AGENIX_HELPER_OP_HOST_SECRET=$AGENIX_HELPER_OP_HOST_SECRET"
      $GUM style --foreground 245 "Using 1Password for passphrase..."
      id="$(run_rage_with_pinentry "$AGENIX_HELPER_OP_HOST_SECRET" "$AGE_IDENTITY_ENCRYPTED" "-d")"
    else
      if [[ -z "${AGENIX_HELPER_OP_HOST_SECRET:-}" ]]; then
        log_debug "AGENIX_HELPER_OP_HOST_SECRET not set"
      fi
      log_debug "Using interactive passphrase prompt for host identity"
      $GUM style --foreground 255 --border rounded --border-foreground 208 --padding "1 2" --margin "1 0" \
        "⚠️  Unlocking agenix identities"
      $GUM style --foreground 245 --italic "Enter passphrase for $AGE_IDENTITY_ENCRYPTED"
      id="$($RAGE -d "$AGE_IDENTITY_ENCRYPTED" 2>&1 || true)"
      log_debug "rage output length: ${#id}"
    fi

    if [[ -z "$id" ]] || [[ "$id" =~ "incorrect" ]] || [[ "$id" =~ "error" ]]; then
      log_debug "Decryption failed - id empty: $([[ -z "$id" ]] && echo yes || echo no), contains 'incorrect': $([[ "$id" =~ "incorrect" ]] && echo yes || echo no), contains 'error': $([[ "$id" =~ "error" ]] && echo yes || echo no)"
      log_error "Failed to decrypt host identity (incorrect passphrase?)"
      return 1
    fi
    log_debug "Host identity decryption successful"
  fi

  if [[ -f "$AGE_IDENTITY_FILE" ]]; then
    mv "$AGE_IDENTITY_FILE" "$AGE_IDENTITY_BACKUP"
  fi

  mkdir -p "$AGE_IDENTITY_DIR"
  chmod 700 "$AGE_IDENTITY_DIR"
  touch "$AGE_IDENTITY_BACKUP" 2>/dev/null || true

  echo "$id" >"$AGE_IDENTITY_FILE"
  chmod 600 "$AGE_IDENTITY_FILE" "$AGE_IDENTITY_BACKUP" 2>/dev/null || true

  # agenix-rekey evaluates ALL host configs, so we need static paths that don't vary by user
  ln -sf "$AGE_IDENTITY_FILE" /tmp/host_id_age
  ln -sf "$AGE_IDENTITY_BACKUP" /tmp/host_id_age_

  if [[ "$quiet" != "quiet" ]]; then
    $GUM style --foreground 82 "🔓 Host identity unlocked at $AGE_IDENTITY_FILE"
    $GUM style --foreground 245 "   Symlinked to /tmp/host_id_age for agenix-rekey"
  fi

  if [[ -f "$AGE_USER_IDENTITY_ENCRYPTED" ]]; then
    log_debug "User identity encrypted file exists: $AGE_USER_IDENTITY_ENCRYPTED"
    local user_id=""

    log_debug "Trying to decrypt user identity with host identity file..."
    user_id="$($RAGE -d -i "$AGE_IDENTITY_FILE" "$AGE_USER_IDENTITY_ENCRYPTED" 2>/dev/null || true)"
    log_debug "Decrypt with host identity result length: ${#user_id}"

    if [[ -z "$user_id" ]] || [[ "$user_id" =~ "error" ]] || [[ "$user_id" =~ "incorrect" ]]; then
      log_debug "Host identity decrypt failed, trying pinentry/interactive..."
      if has_pinentry_tools && [[ -n "${AGENIX_HELPER_OP_USER_SECRET:-}" ]]; then
        log_debug "Using pinentry-1password for user identity"
        log_debug "AGENIX_HELPER_OP_USER_SECRET=$AGENIX_HELPER_OP_USER_SECRET"
        user_id="$(run_rage_with_pinentry "$AGENIX_HELPER_OP_USER_SECRET" "$AGE_USER_IDENTITY_ENCRYPTED" "-d")"
      else
        if [[ -z "${AGENIX_HELPER_OP_USER_SECRET:-}" ]]; then
          log_debug "AGENIX_HELPER_OP_USER_SECRET not set"
        fi
        log_debug "Using interactive passphrase for user identity"
        if [[ "$quiet" != "quiet" ]]; then
          $GUM style --foreground 245 --italic "Enter passphrase for $AGE_USER_IDENTITY_ENCRYPTED"
        fi
        user_id="$($RAGE -d "$AGE_USER_IDENTITY_ENCRYPTED" 2>&1 || true)"
        log_debug "Interactive decrypt result length: ${#user_id}"
      fi
    fi

    if [[ -n "$user_id" ]] && [[ ! "$user_id" =~ "error" ]] && [[ ! "$user_id" =~ "incorrect" ]]; then
      log_debug "User identity decryption successful"
      mkdir -p "$(dirname "$AGE_USER_IDENTITY_FILE")"
      printf '%s\n' "$user_id" >"$AGE_USER_IDENTITY_FILE"
      chmod 600 "$AGE_USER_IDENTITY_FILE"

      if [[ "$quiet" != "quiet" ]]; then
        $GUM style --foreground 82 "🔓 User identity unlocked at $AGE_USER_IDENTITY_FILE"
      fi
    elif [[ "$quiet" != "quiet" ]]; then
      log_debug "User identity decryption failed"
      log_warn "Could not decrypt user identity at $AGE_USER_IDENTITY_ENCRYPTED"
    fi
  else
    log_debug "User identity encrypted file not found: $AGE_USER_IDENTITY_ENCRYPTED"
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
    log_success "Host identity is unlocked at $AGE_IDENTITY_FILE"
  else
    log_warn "Host identity is locked"
    status=1
  fi

  if [[ -f "$AGE_USER_IDENTITY_FILE" ]]; then
    log_success "User identity is unlocked at $AGE_USER_IDENTITY_FILE"
  else
    log_warn "User identity is locked"
  fi

  return $status
}

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
    echo ""
    echo "1Password integration (via pinentry-1password):"
    echo "  AGENIX_HELPER_OP_HOST_SECRET - 1Password reference for host identity passphrase"
    echo "  AGENIX_HELPER_OP_USER_SECRET - 1Password reference for user identity passphrase"
    echo ""
    echo "  Example: export AGENIX_HELPER_OP_HOST_SECRET='op://vault/age-identity/passphrase'"
    echo ""
    echo "  Requires: op CLI and pinentry-1password package"
    echo ""
    echo "Debugging:"
    echo "  AGENIX_HELPER_DEBUG=1 - Enable debug logging to see which code paths are taken"
    exit 1
    ;;
esac
