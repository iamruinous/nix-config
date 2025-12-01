# microvm-backup - Backup MicroVM persistent data locally
#
# This script creates local backups of MicroVM persistent data
# stored in /persistent/microvms/

VERSION="1.0.0"
SCRIPT_NAME=$(basename "$0")

# Default values
MICROVM_BASE="/persistent/microvms"
BACKUP_BASE="/backup/microvms"
DRY_RUN=false
VERBOSE=false
INCLUDE_OVERLAY=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME <command> [options]

Backup MicroVM persistent data locally.

Commands:
    list                    List available MicroVMs on this host
    status <vm>             Show status and size of a MicroVM's data
    backup <vm> [dest]      Backup a MicroVM (default: $BACKUP_BASE/<vm>)
    backup-all [dest]       Backup all MicroVMs
    restore <backup> <vm>   Restore a MicroVM from backup
    verify <vm>             Verify integrity of a MicroVM's persistent data

Options:
    -n, --dry-run           Show what would be done without making changes
    -v, --verbose           Enable verbose output
    -o, --overlay           Also backup the nix-store overlay image
    -b, --base <path>       Base path for MicroVM data (default: $MICROVM_BASE)
    -d, --dest <path>       Backup destination base (default: $BACKUP_BASE)
    -h, --help              Show this help message
    --version               Show version information

Examples:
    # List MicroVMs on current host
    $SCRIPT_NAME list

    # Check status of a specific VM
    $SCRIPT_NAME status messy-tty

    # Backup messy-tty to default location
    $SCRIPT_NAME backup messy-tty

    # Backup to custom location
    $SCRIPT_NAME backup messy-tty /mnt/backup/vms

    # Backup with overlay image
    $SCRIPT_NAME backup -o messy-tty

    # Dry-run to see what would be backed up
    $SCRIPT_NAME backup -n messy-tty

    # Backup all VMs
    $SCRIPT_NAME backup-all

    # Restore from backup
    $SCRIPT_NAME restore /backup/microvms/messy-tty messy-tty

EOF
}

version() {
    echo "$SCRIPT_NAME version $VERSION"
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
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*"
    fi
}

# Check if a VM exists locally
vm_exists() {
    local vm_name="$1"
    local vm_path="$MICROVM_BASE/$vm_name/persistent"
    [[ -d "$vm_path" ]]
}

# Get the overlay image path for a VM
get_overlay_path() {
    local vm_name="$1"
    echo "/var/lib/microvms/$vm_name/nix-store-overlay.img"
}

# Check if VM is running
vm_is_running() {
    local vm_name="$1"
    systemctl is-active --quiet "microvm@$vm_name" 2>/dev/null
}

# List available MicroVMs
cmd_list() {
    log_info "MicroVMs in $MICROVM_BASE:"
    echo ""

    if [[ ! -d "$MICROVM_BASE" ]]; then
        log_warn "MicroVM base directory does not exist: $MICROVM_BASE"
        return 1
    fi

    local found=false
    for vm_dir in "$MICROVM_BASE"/*/; do
        if [[ -d "${vm_dir}persistent" ]]; then
            found=true
            local vm_name
            vm_name=$(basename "$vm_dir")
            local size
            size=$(du -sh "${vm_dir}persistent" 2>/dev/null | cut -f1)
            local status="stopped"

            if vm_is_running "$vm_name"; then
                status="${GREEN}running${NC}"
            else
                status="${YELLOW}stopped${NC}"
            fi

            printf "  %-20s %10s  [%b]\n" "$vm_name" "$size" "$status"
        fi
    done

    if [[ "$found" == "false" ]]; then
        log_warn "No MicroVMs found"
    fi
    echo ""
}

# Show status of a VM
cmd_status() {
    local vm_name="$1"

    if [[ -z "$vm_name" ]]; then
        log_error "VM name required"
        usage
        exit 1
    fi

    local vm_path="$MICROVM_BASE/$vm_name/persistent"
    local overlay_path
    overlay_path=$(get_overlay_path "$vm_name")

    echo ""
    echo "MicroVM: $vm_name"
    echo "=========================================="

    # Check if VM exists
    if vm_exists "$vm_name"; then
        log_success "Persistent data exists: $vm_path"
        echo ""
        echo "Persistent data size:"
        du -sh "$vm_path" 2>/dev/null || echo "  Unable to determine size"
        echo ""
        echo "Persistent data breakdown:"
        du -sh "$vm_path"/* 2>/dev/null | sed 's/^/  /' || echo "  No subdirectories"
    else
        log_warn "Persistent data not found: $vm_path"
    fi

    echo ""

    # Check overlay
    if [[ -f "$overlay_path" ]]; then
        local overlay_size
        overlay_size=$(du -sh "$overlay_path" 2>/dev/null | cut -f1)
        log_success "Overlay image exists: $overlay_path ($overlay_size)"
    else
        log_warn "Overlay image not found: $overlay_path"
    fi

    echo ""

    # Check running status
    if vm_is_running "$vm_name"; then
        log_success "VM is currently running"
        log_warn "Stop the VM before backup for data consistency"
    else
        log_info "VM is not running"
    fi

    echo ""
}

# Verify VM data integrity
cmd_verify() {
    local vm_name="$1"

    if [[ -z "$vm_name" ]]; then
        log_error "VM name required"
        usage
        exit 1
    fi

    local vm_path="$MICROVM_BASE/$vm_name/persistent"

    echo ""
    echo "Verifying MicroVM: $vm_name"
    echo "=========================================="

    if ! vm_exists "$vm_name"; then
        log_error "VM does not exist: $vm_name"
        exit 1
    fi

    # Check essential files
    log_info "Checking essential files..."

    local essential_files=(
        "etc/machine-id"
        "etc/ssh/ssh_host_ed25519_key"
    )

    for file in "${essential_files[@]}"; do
        if [[ -f "$vm_path/$file" ]]; then
            log_success "  Found: $file"
        else
            log_warn "  Missing: $file (will be regenerated)"
        fi
    done

    # Check directory structure
    log_info "Checking directory structure..."

    local essential_dirs=(
        "var/lib/nixos"
    )

    for dir in "${essential_dirs[@]}"; do
        if [[ -d "$vm_path/$dir" ]]; then
            log_success "  Found: $dir/"
        else
            log_warn "  Missing: $dir/ (may need to be created)"
        fi
    done

    # Check for user data
    log_info "Checking user data..."
    for user_dir in "$vm_path/home"/*; do
        if [[ -d "$user_dir" ]]; then
            local user
            user=$(basename "$user_dir")
            local user_size
            user_size=$(du -sh "$user_dir" 2>/dev/null | cut -f1)
            log_success "  User data: $user ($user_size)"
        fi
    done

    echo ""
    log_success "Verification complete"
}

# Backup a single VM
cmd_backup() {
    local vm_name=""
    local destination=""

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$vm_name" ]]; then
                    vm_name="$1"
                elif [[ -z "$destination" ]]; then
                    destination="$1"
                else
                    log_error "Too many arguments"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$vm_name" ]]; then
        log_error "VM name required"
        echo "Usage: $SCRIPT_NAME backup <vm-name> [destination]"
        exit 1
    fi

    # Use default destination if not specified
    if [[ -z "$destination" ]]; then
        destination="$BACKUP_BASE/$vm_name"
    fi

    local vm_path="$MICROVM_BASE/$vm_name/persistent"
    local overlay_path
    overlay_path=$(get_overlay_path "$vm_name")
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="$destination/$timestamp"

    if ! vm_exists "$vm_name"; then
        log_error "VM does not exist: $vm_name"
        exit 1
    fi

    echo ""
    log_info "Backing up MicroVM: $vm_name"
    log_info "Source: $vm_path"
    log_info "Destination: $backup_dir"
    echo ""

    # Check if VM is running
    if vm_is_running "$vm_name"; then
        log_warn "VM is running - backup may be inconsistent"
        log_warn "Consider stopping the VM first: systemctl stop microvm@$vm_name"
        echo ""
    fi

    # Create backup directory
    if [[ "$DRY_RUN" != "true" ]]; then
        mkdir -p "$backup_dir/persistent"
    fi

    # Build rsync options
    local rsync_opts=(-avz --progress)

    if [[ "$DRY_RUN" == "true" ]]; then
        rsync_opts+=(--dry-run)
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        rsync_opts+=(-v)
    fi

    # Backup persistent data
    log_info "Backing up persistent data..."
    log_verbose "rsync ${rsync_opts[*]} $vm_path/ $backup_dir/persistent/"

    rsync "${rsync_opts[@]}" "$vm_path/" "$backup_dir/persistent/"

    if [[ "$DRY_RUN" != "true" ]]; then
        log_success "Persistent data backed up"
    fi

    # Optionally backup overlay
    if [[ "$INCLUDE_OVERLAY" == "true" ]]; then
        if [[ -f "$overlay_path" ]]; then
            log_info "Backing up overlay image..."
            log_verbose "rsync ${rsync_opts[*]} $overlay_path $backup_dir/"

            rsync "${rsync_opts[@]}" "$overlay_path" "$backup_dir/"

            if [[ "$DRY_RUN" != "true" ]]; then
                log_success "Overlay image backed up"
            fi
        else
            log_warn "Overlay image not found, skipping: $overlay_path"
        fi
    fi

    # Create latest symlink
    if [[ "$DRY_RUN" != "true" ]]; then
        ln -sfn "$timestamp" "$destination/latest"
        log_info "Created 'latest' symlink"
    fi

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Backup simulation complete"
    else
        log_success "Backup complete: $backup_dir"
    fi
}

# Backup all VMs
cmd_backup_all() {
    local destination="${1:-$BACKUP_BASE}"

    log_info "Backing up all MicroVMs to: $destination"
    echo ""

    if [[ ! -d "$MICROVM_BASE" ]]; then
        log_error "MicroVM base directory does not exist: $MICROVM_BASE"
        exit 1
    fi

    local count=0
    for vm_dir in "$MICROVM_BASE"/*/; do
        if [[ -d "${vm_dir}persistent" ]]; then
            local vm_name
            vm_name=$(basename "$vm_dir")
            echo "----------------------------------------"
            cmd_backup "$vm_name" "$destination/$vm_name"
            ((count++))
        fi
    done

    echo ""
    echo "========================================"
    log_success "Backed up $count MicroVM(s)"
}

# Restore a VM from backup
cmd_restore() {
    local source=""
    local vm_name=""

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$source" ]]; then
                    source="$1"
                elif [[ -z "$vm_name" ]]; then
                    vm_name="$1"
                else
                    log_error "Too many arguments"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$source" || -z "$vm_name" ]]; then
        log_error "Source backup and VM name required"
        echo "Usage: $SCRIPT_NAME restore <backup-path> <vm-name>"
        exit 1
    fi

    local vm_path="$MICROVM_BASE/$vm_name/persistent"

    echo ""
    log_info "Restoring MicroVM: $vm_name"
    log_info "Source: $source"
    log_info "Destination: $vm_path"
    echo ""

    # Check if VM is running
    if vm_is_running "$vm_name"; then
        log_error "VM is running. Stop it first: systemctl stop microvm@$vm_name"
        exit 1
    fi

    # Determine source path
    local source_persistent="$source"
    if [[ -d "$source/persistent" ]]; then
        source_persistent="$source/persistent"
    fi

    if [[ ! -d "$source_persistent" ]]; then
        log_error "Backup not found: $source_persistent"
        exit 1
    fi

    # Create directory structure if needed
    if [[ "$DRY_RUN" != "true" ]]; then
        log_info "Ensuring directory exists: $vm_path"
        sudo mkdir -p "$vm_path"
    fi

    # Build rsync options
    local rsync_opts=(-avz --progress)

    if [[ "$DRY_RUN" == "true" ]]; then
        rsync_opts+=(--dry-run)
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        rsync_opts+=(-v)
    fi

    # Restore persistent data
    log_info "Restoring persistent data..."
    log_verbose "rsync ${rsync_opts[*]} $source_persistent/ $vm_path/"

    rsync "${rsync_opts[@]}" "$source_persistent/" "$vm_path/"

    if [[ "$DRY_RUN" != "true" ]]; then
        log_success "Persistent data restored"

        # Fix permissions
        log_info "Fixing permissions..."
        sudo chown -R root:root "$vm_path"
        sudo chmod 0770 "$vm_path"
    fi

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Restore simulation complete"
    else
        log_success "Restore complete!"
        echo ""
        echo "Start the VM with: systemctl start microvm@$vm_name"
    fi
}

# Main entry point
main() {
    local command=""

    # Parse global options first
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --version)
                version
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -o|--overlay)
                INCLUDE_OVERLAY=true
                shift
                ;;
            -b|--base)
                MICROVM_BASE="$2"
                shift 2
                ;;
            -d|--dest)
                BACKUP_BASE="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$command" ]]; then
                    command="$1"
                    shift
                    break
                fi
                ;;
        esac
    done

    if [[ -z "$command" ]]; then
        usage
        exit 1
    fi

    case "$command" in
        list)
            cmd_list
            ;;
        status)
            cmd_status "$@"
            ;;
        verify)
            cmd_verify "$@"
            ;;
        backup)
            cmd_backup "$@"
            ;;
        backup-all)
            cmd_backup_all "$@"
            ;;
        restore)
            cmd_restore "$@"
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
