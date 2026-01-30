#!/usr/bin/env bash
#
# migrate-to-infisical.sh
# 
# Bulk migrate agenix secrets to Infisical
#
# Prerequisites:
#   1. Run: agenix-helper unlock
#   2. Run: infisical login (or set INFISICAL_TOKEN)
#   3. Create project in Infisical with "homelab" environment
#
# Usage:
#   ./scripts/migrate-to-infisical.sh [--dry-run] [--host <hostname>] [--project-id <id>]
#
# Examples:
#   ./scripts/migrate-to-infisical.sh --dry-run                    # Preview all migrations
#   ./scripts/migrate-to-infisical.sh --host monolith              # Migrate only monolith secrets
#   ./scripts/migrate-to-infisical.sh --project-id abc123          # Specify Infisical project

set -euo pipefail

# Configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFISICAL_ENV="${INFISICAL_ENV:-homelab}"
INFISICAL_API_URL="${INFISICAL_API_URL:-https://infisical.meskill.farm}"
TMP_DIR="/tmp/infisical-migration-$$"
DRY_RUN=false
TARGET_HOST=""
PROJECT_ID=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
MIGRATED=0
SKIPPED=0
FAILED=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Migrate agenix secrets to Infisical.

Options:
    --dry-run           Preview migrations without actually importing
    --host <name>       Only migrate secrets for specified host
    --project-id <id>   Infisical project ID (required for machine identity auth)
    --env <name>        Infisical environment (default: homelab)
    --help              Show this help message

Environment Variables:
    INFISICAL_TOKEN     Machine identity or service token
    INFISICAL_API_URL   Infisical API URL (default: https://infisical.meskill.farm)
    INFISICAL_ENV       Infisical environment (default: homelab)

Prerequisites:
    1. agenix-helper unlock   # Unlock your age identity
    2. infisical login        # Or set INFISICAL_TOKEN

EOF
    exit 0
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

cleanup() {
    if [[ -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}

trap cleanup EXIT

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check agenix
    if ! command -v agenix &>/dev/null; then
        log_error "agenix not found. Run: nix shell nixpkgs#agenix"
        exit 1
    fi
    
    # Check infisical
    if ! command -v infisical &>/dev/null; then
        log_error "infisical CLI not found. Run: nix shell nixpkgs#infisical"
        exit 1
    fi
    
    # Check age identity is unlocked
    if [[ ! -f /tmp/host_id_age ]]; then
        log_error "Age identity not unlocked. Run: agenix-helper unlock"
        exit 1
    fi
    
    # Check infisical auth
    if [[ -z "${INFISICAL_TOKEN:-}" ]]; then
        if ! infisical user &>/dev/null 2>&1; then
            log_error "Not logged in to Infisical. Run: infisical login"
            exit 1
        fi
    fi
    
    log_success "Prerequisites OK"
}

create_folder_if_needed() {
    local path="$1"
    
    if $DRY_RUN; then
        log_info "[DRY-RUN] Would create folder: $path"
        return 0
    fi
    
    # Create parent folders recursively
    local current_path=""
    IFS='/' read -ra PARTS <<< "${path#/}"
    for part in "${PARTS[@]}"; do
        if [[ -n "$part" ]]; then
            local parent_path="${current_path:-/}"
            current_path="${current_path}/${part}"
            
            # Try to create folder (ignore if exists)
            infisical secrets folders create \
                --path="$parent_path" \
                --name="$part" \
                --env="$INFISICAL_ENV" \
                ${PROJECT_ID:+--projectId="$PROJECT_ID"} \
                2>/dev/null || true
        fi
    done
}

migrate_env_file() {
    local age_file="$1"
    local infisical_path="$2"
    local secret_name="$3"
    
    log_info "Processing: $age_file"
    log_info "  -> Infisical path: $infisical_path"
    
    if [[ ! -f "$age_file" ]]; then
        log_warn "  File not found, skipping"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi
    
    local tmp_file="$TMP_DIR/$(basename "$age_file" .age)"
    
    if ! (cd "$REPO_ROOT" && agenix view "$age_file" > "$tmp_file" 2>/dev/null); then
        log_error "  Failed to decrypt"
        FAILED=$((FAILED + 1))
        return 1
    fi
    
    # Check if it's an env file (KEY=VALUE format) or raw content
    if grep -qE '^[A-Z_][A-Z0-9_]*=' "$tmp_file" 2>/dev/null; then
        # It's an env file - import as multiple secrets
        if $DRY_RUN; then
            log_info "  [DRY-RUN] Would import env file with secrets:"
            grep -E '^[A-Z_][A-Z0-9_]*=' "$tmp_file" | cut -d= -f1 | while read -r key; do
                log_info "    - $key"
            done
        else
            create_folder_if_needed "$infisical_path"
            
            if infisical secrets set \
                --file="$tmp_file" \
                --env="$INFISICAL_ENV" \
                --path="$infisical_path" \
                ${PROJECT_ID:+--projectId="$PROJECT_ID"} \
                2>/dev/null; then
                log_success "  Imported env file"
                MIGRATED=$((MIGRATED + 1))
            else
                log_error "  Failed to import"
                FAILED=$((FAILED + 1))
            fi
        fi
    else
        # It's a raw file (config, key, etc) - import as single secret
        if $DRY_RUN; then
            log_info "  [DRY-RUN] Would import as single secret: $secret_name"
        else
            create_folder_if_needed "$infisical_path"
            
            if infisical secrets set \
                "${secret_name}=@${tmp_file}" \
                --env="$INFISICAL_ENV" \
                --path="$infisical_path" \
                ${PROJECT_ID:+--projectId="$PROJECT_ID"} \
                2>/dev/null; then
                log_success "  Imported as: $secret_name"
                MIGRATED=$((MIGRATED + 1))
            else
                log_error "  Failed to import"
                FAILED=$((FAILED + 1))
            fi
        fi
    fi
    
    # Secure delete
    rm -f "$tmp_file"
}

migrate_host_secrets() {
    local host="$1"
    local host_dir="$REPO_ROOT/hosts/$host"
    
    if [[ ! -d "$host_dir" ]]; then
        log_warn "Host directory not found: $host_dir"
        return 0
    fi
    
    log_info "=== Migrating secrets for host: $host ==="
    
    # Docker env files
    if [[ -d "$host_dir/files/docker/env" ]]; then
        for age_file in "$host_dir"/files/docker/env/*.age; do
            [[ -f "$age_file" ]] || continue
            local basename=$(basename "$age_file" .env.age)
            migrate_env_file "$age_file" "/nixos/$host/docker" "${host^^}_${basename^^}_ENV"
        done
    fi
    
    # Caddy secrets
    if [[ -f "$host_dir/files/caddy/secrets.age" ]]; then
        migrate_env_file "$host_dir/files/caddy/secrets.age" "/nixos/$host/caddy" "${host^^}_CADDY_SECRETS"
    fi
    if [[ -f "$host_dir/files/caddy/env.age" ]]; then
        migrate_env_file "$host_dir/files/caddy/env.age" "/nixos/$host/caddy" "${host^^}_CADDY_ENV"
    fi
    
    # Cloudflared
    if [[ -d "$host_dir/files/cloudflared" ]]; then
        for age_file in "$host_dir"/files/cloudflared/*.age; do
            [[ -f "$age_file" ]] || continue
            local basename=$(basename "$age_file" .age)
            local secret_name="${host^^}_CLOUDFLARED_${basename^^}"
            secret_name="${secret_name//-/_}"
            secret_name="${secret_name//./_}"
            migrate_env_file "$age_file" "/nixos/$host/cloudflared" "$secret_name"
        done
    fi
    
    # Mosquitto
    if [[ -d "$host_dir/files/mosquitto" ]]; then
        for age_file in "$host_dir"/files/mosquitto/*.age; do
            [[ -f "$age_file" ]] || continue
            local basename=$(basename "$age_file" .age)
            local secret_name="${host^^}_MOSQUITTO_${basename^^}"
            secret_name="${secret_name//-/_}"
            secret_name="${secret_name//./_}"
            migrate_env_file "$age_file" "/nixos/$host/mosquitto" "$secret_name"
        done
    fi
    
    # ACME/Cloudflare
    if [[ -f "$host_dir/files/acme/cloudflare.env.age" ]]; then
        migrate_env_file "$host_dir/files/acme/cloudflare.env.age" "/nixos/$host/acme" "${host^^}_ACME_CLOUDFLARE_ENV"
    fi
    
    # Forgejo runner
    if [[ -f "$host_dir/files/forgejo-runner/token.age" ]]; then
        migrate_env_file "$host_dir/files/forgejo-runner/token.age" "/nixos/$host/forgejo" "${host^^}_FORGEJO_RUNNER_TOKEN"
    fi
    
    # Glance
    if [[ -f "$host_dir/files/glance/glance.yml.age" ]]; then
        migrate_env_file "$host_dir/files/glance/glance.yml.age" "/nixos/$host/glance" "${host^^}_GLANCE_CONFIG"
    fi
    
    # RTL_433
    if [[ -d "$host_dir/files/rtl_433" ]]; then
        for age_file in "$host_dir"/files/rtl_433/*.age; do
            [[ -f "$age_file" ]] || continue
            local basename=$(basename "$age_file" .age)
            local secret_name="${host^^}_${basename^^}"
            secret_name="${secret_name//-/_}"
            secret_name="${secret_name//./_}"
            migrate_env_file "$age_file" "/nixos/$host/rtl433" "$secret_name"
        done
    fi
    
    # MQTT Explorer
    if [[ -f "$host_dir/files/mqtt-explorer/settings.json.age" ]]; then
        migrate_env_file "$host_dir/files/mqtt-explorer/settings.json.age" "/nixos/$host/mqtt-explorer" "${host^^}_MQTT_EXPLORER_SETTINGS"
    fi
    
    # Meshtastic
    if [[ -f "$host_dir/files/meshtastic-message-relay/config.yaml.age" ]]; then
        migrate_env_file "$host_dir/files/meshtastic-message-relay/config.yaml.age" "/nixos/$host/meshtastic" "${host^^}_MESHTASTIC_RELAY_CONFIG"
    fi
    
    # Harmonia
    if [[ -f "$host_dir/files/harmonia/signing-key.sec.age" ]]; then
        migrate_env_file "$host_dir/files/harmonia/signing-key.sec.age" "/nixos/$host/harmonia" "${host^^}_HARMONIA_SIGNING_KEY"
    fi
    
    # Weaviate
    if [[ -f "$host_dir/files/weaviate/env.age" ]]; then
        migrate_env_file "$host_dir/files/weaviate/env.age" "/nixos/$host/weaviate" "${host^^}_WEAVIATE_ENV"
    fi
    
    # Budgey assistant
    if [[ -d "$host_dir/files/budgey-assistant" ]]; then
        for age_file in "$host_dir"/files/budgey-assistant/*.age; do
            [[ -f "$age_file" ]] || continue
            local basename=$(basename "$age_file" .age)
            local secret_name="${host^^}_BUDGEY_${basename^^}"
            secret_name="${secret_name//-/_}"
            migrate_env_file "$age_file" "/nixos/$host/budgey" "$secret_name"
        done
    fi
    
    # Moltbot (chassis specific)
    if [[ -d "$host_dir/files/moltbot" ]]; then
        for age_file in "$host_dir"/files/moltbot/*.age; do
            [[ -f "$age_file" ]] || continue
            local basename=$(basename "$age_file" .age)
            local secret_name="MOLTBOT_${basename^^}"
            secret_name="${secret_name//-/_}"
            migrate_env_file "$age_file" "/nixos/$host/moltbot" "$secret_name"
        done
    fi
    
    # Messy attributes editor
    if [[ -f "$host_dir/files/messy-attributes-editor/env.age" ]]; then
        migrate_env_file "$host_dir/files/messy-attributes-editor/env.age" "/nixos/$host/messy-attributes-editor" "${host^^}_MESSY_ATTRIBUTES_EDITOR_ENV"
    fi
    
    # Home-manager opencode secrets (chassis)
    if [[ -d "$host_dir/users/jmeskill/files/opencode" ]]; then
        if [[ -f "$host_dir/users/jmeskill/files/opencode/common.env.age" ]]; then
            migrate_env_file "$host_dir/users/jmeskill/files/opencode/common.env.age" "/nixos/$host/opencode" "OPENCODE_COMMON_ENV"
        fi
        if [[ -d "$host_dir/users/jmeskill/files/opencode/projects" ]]; then
            for age_file in "$host_dir"/users/jmeskill/files/opencode/projects/*.age; do
                [[ -f "$age_file" ]] || continue
                local basename=$(basename "$age_file" .env.age)
                migrate_env_file "$age_file" "/nixos/$host/opencode/projects" "OPENCODE_PROJECT_${basename^^}_ENV"
            done
        fi
    fi
}

migrate_shared_secrets() {
    log_info "=== Migrating shared secrets ==="
    
    # User passwords
    if [[ -f "$REPO_ROOT/users/jmeskill/password.age" ]]; then
        migrate_env_file "$REPO_ROOT/users/jmeskill/password.age" "/nixos/shared/users" "USER_PASSWORD_JMESKILL"
    fi
    
    # Git identity
    if [[ -f "$REPO_ROOT/users/git/id_ed25519.age" ]]; then
        migrate_env_file "$REPO_ROOT/users/git/id_ed25519.age" "/nixos/shared/users" "GIT_ID_ED25519"
    fi
    
    # Shared configs
    local configs_dir="$REPO_ROOT/files/configs"
    
    if [[ -f "$configs_dir/restic/restic-password.age" ]]; then
        migrate_env_file "$configs_dir/restic/restic-password.age" "/nixos/shared/restic" "RESTIC_PASSWORD"
    fi
    
    if [[ -f "$configs_dir/nut/password.age" ]]; then
        migrate_env_file "$configs_dir/nut/password.age" "/nixos/shared/nut" "NUT_CLIENT_PASSWORD"
    fi
    
    if [[ -f "$configs_dir/vdirsyncer/config.age" ]]; then
        migrate_env_file "$configs_dir/vdirsyncer/config.age" "/nixos/shared/vdirsyncer" "VDIRSYNCER_CONFIG"
    fi
    
    if [[ -f "$configs_dir/vdirsyncer/google_jadeisfalling_token.age" ]]; then
        migrate_env_file "$configs_dir/vdirsyncer/google_jadeisfalling_token.age" "/nixos/shared/vdirsyncer" "VDIRSYNCER_GOOGLE_TOKEN"
    fi
    
    if [[ -f "$configs_dir/todoist/config.json.age" ]]; then
        migrate_env_file "$configs_dir/todoist/config.json.age" "/nixos/shared/todoist" "TODOIST_CONFIG"
    fi
    
    if [[ -f "$configs_dir/tea/config.yml.age" ]]; then
        migrate_env_file "$configs_dir/tea/config.yml.age" "/nixos/shared/tea" "TEA_CONFIG"
    fi
    
    if [[ -f "$configs_dir/budgey/deploy-key.age" ]]; then
        migrate_env_file "$configs_dir/budgey/deploy-key.age" "/nixos/shared/budgey" "BUDGEY_DEPLOY_KEY"
    fi
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --host)
                TARGET_HOST="$2"
                shift 2
                ;;
            --project-id)
                PROJECT_ID="$2"
                shift 2
                ;;
            --env)
                INFISICAL_ENV="$2"
                shift 2
                ;;
            --help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    # Setup
    mkdir -p "$TMP_DIR"
    chmod 700 "$TMP_DIR"
    
    export INFISICAL_API_URL
    export INFISICAL_DISABLE_UPDATE_CHECK=true
    
    if $DRY_RUN; then
        log_warn "=== DRY RUN MODE - No changes will be made ==="
    fi
    
    check_prerequisites
    
    # Migrate
    if [[ -n "$TARGET_HOST" ]]; then
        migrate_host_secrets "$TARGET_HOST"
    else
        # Migrate all hosts
        migrate_shared_secrets
        
        for host in chassis monolith pilaster zenith obelisk tty-ruinous-social azimuth armistice; do
            if [[ -d "$REPO_ROOT/hosts/$host" ]]; then
                migrate_host_secrets "$host"
            fi
        done
    fi
    
    # Summary
    echo ""
    log_info "=== Migration Summary ==="
    log_success "Migrated: $MIGRATED"
    log_warn "Skipped:  $SKIPPED"
    if [[ $FAILED -gt 0 ]]; then
        log_error "Failed:   $FAILED"
    else
        log_info "Failed:   $FAILED"
    fi
    
    if $DRY_RUN; then
        echo ""
        log_warn "This was a dry run. Run without --dry-run to actually migrate."
    fi
}

main "$@"
