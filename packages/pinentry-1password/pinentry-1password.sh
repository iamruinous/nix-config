#!/usr/bin/env bash
# 1Password CLI Pinentry for GPG-Agent and other pinentry-compatible programs
# Based on https://gist.github.com/mrgrain/9c3519952d9af811bd7bf50bfcfaa16f
# Protocol implementation based on pinentry-bash by legionus

set -euo pipefail

# GPG Error codes
GPG_ERR_NO_ERROR=0
GPG_ERR_CANCELED=99
GPG_ERR_ASS_PARAMETER=280
GPG_ERR_GENERAL=83886179

# Version information
VERSION="0.1.0"

# Variables to store pinentry state
DESCRIPTION=""
PROMPT=""
TITLE=""
OK_BUTTON=""
CANCEL_BUTTON=""
ERROR_TEXT=""
TIMEOUT=""
KEYINFO=""

# Function to send assuan result
assuan_result() {
  local code="$1"
  shift
  if [[ "$code" -eq "$GPG_ERR_NO_ERROR" ]]; then
    echo "OK${*:+ $*}"
  else
    echo "ERR $code${*:+ $*}"
  fi
}

# Check if OP_PIN_ITEM is set (only when GETPIN is called)
check_op_config() {
  if [[ -z "${OP_PIN_ITEM:-}" ]]; then
    assuan_result "$GPG_ERR_GENERAL" "No OP_PIN_ITEM configured"
    return 1
  fi

  if ! command -v op &> /dev/null; then
    assuan_result "$GPG_ERR_GENERAL" "1Password CLI not found"
    return 1
  fi
  return 0
}

# Send initial OK greeting
echo "OK Pleased to meet you"

# Main pinentry protocol loop
while IFS= read -r line; do
  # Parse command and arguments
  cmd=${line%% *}
  args=${line#* }
  [[ "$cmd" == "$line" ]] && args=""

  case "$cmd" in
    \#*)
      # Comments - ignore
      continue
      ;;

    GETPIN)
      # Retrieve the passphrase from 1Password
      if ! check_op_config; then
        continue
      fi

      if pin=$(op read "$OP_PIN_ITEM" 2>/dev/null); then
        echo "D $pin"
        assuan_result "$GPG_ERR_NO_ERROR"
      else
        assuan_result "$GPG_ERR_GENERAL" "Failed to read from 1Password"
      fi
      ;;

    GETINFO)
      case "$args" in
        version)
          echo "D $VERSION"
          assuan_result "$GPG_ERR_NO_ERROR"
          ;;
        pid)
          echo "D $$"
          assuan_result "$GPG_ERR_NO_ERROR"
          ;;
        flavor)
          echo "D 1password"
          assuan_result "$GPG_ERR_NO_ERROR"
          ;;
        ttyinfo)
          echo "D ${GPG_TTY:-} ${TERM:-} -"
          assuan_result "$GPG_ERR_NO_ERROR"
          ;;
        *)
          assuan_result "$GPG_ERR_ASS_PARAMETER" "Unknown GETINFO parameter"
          ;;
      esac
      ;;

    SETDESC)
      DESCRIPTION="$args"
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    SETPROMPT)
      PROMPT="$args"
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    SETTITLE)
      TITLE="$args"
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    SETOK)
      OK_BUTTON="$args"
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    SETCANCEL)
      CANCEL_BUTTON="$args"
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    SETNOTOK)
      # Not used but acknowledged
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    SETERROR)
      ERROR_TEXT="$args"
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    SETREPEAT|SETREPEATERROR)
      # Password confirmation not supported in 1Password mode
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    SETTIMEOUT)
      TIMEOUT="$args"
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    SETKEYINFO)
      KEYINFO="$args"
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    OPTION)
      # Accept options but don't need to act on them
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    CONFIRM)
      # Confirmation dialogs always succeed (assume yes)
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    MESSAGE)
      # Messages are acknowledged but not displayed
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    BYE)
      assuan_result "$GPG_ERR_NO_ERROR"
      exit 0
      ;;

    RESET|NOP)
      # Reset state or no-op
      DESCRIPTION=""
      PROMPT=""
      TITLE=""
      OK_BUTTON=""
      CANCEL_BUTTON=""
      ERROR_TEXT=""
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;

    *)
      # Unknown commands return OK to avoid breaking the protocol
      assuan_result "$GPG_ERR_NO_ERROR"
      ;;
  esac
done
