# microvm-transfer - Transfer MicroVMs between hosts
#
# This script transfers MicroVM persistent data to/from remote hosts
# via SSH and rsync.

VERSION="1.0.0"
SCRIPT_NAME=$(basename "$0")

# Default values
MICROVM_BASE="/persistent/microvms"
DRY_RUN=false
VERBOSE=false
INCLUDE_OVERLAY=false
STOP_VM=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME <command> [options]

Transfer MicroVM persistent data between hosts via SSH.

Commands:
    send <vm> <host>        Send a MicroVM to a remote host
    receive <host> <vm>     Receive a MicroVM from a remote host
    sync <vm> <host>        Bidirectional sync (dangerous - use carefully)

Options:
    -n, --dry-run           Show what would be done without making changes
    -v, --verbose           Enable verbose output
    -o, --overlay           Also transfer the nix-store overlay image
    -s, --stop              Stop the VM before transfer (requires root)
    -b, --base <path>       Base path for MicroVM data (default: $MICROVM_BASE)
    -p, --port <port>       SSH port (default: 22)
    -h, --help              Show this help message
    --version               Show version information

Examples:
    # Send messy-tty to another host
    $SCRIPT_NAME send messy-tty user@newhost

    # Send with overlay image
    $SCRIPT_NAME send -o messy-tty user@newhost

    # Stop VM before sending (for consistency)
    $SCRIPT_NAME send -s messy-tty user@newhost

    # Dry-run to preview transfer
    $SCRIPT_NAME send -n messy-tty user@newhost

    # Receive a VM from remote host
    $SCRIPT_NAME receive user@oldhost messy-tty

    # Use custom SSH port
    $SCRIPT_NAME send -p 2222 messy-tty user@newhost

Notes:
    - The remote host must have the same directory structure
    - Stop the VM on both ends for data consistency
    - Use with microvm-backup first to create a local backup

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

# Stop a VM
stop_vm() {
    local vm_name="$1"
    log_info "Stopping MicroVM: $vm_name"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would run: systemctl stop microvm@$vm_name"
    else
        sudo systemctl stop "microvm@$vm_name"
        log_success "VM stopped"
    fi
}

# Parse SSH host string
parse_ssh_host() {
    local host_string="$1"
    local user=""
    local host=""
    local port="${SSH_PORT:-22}"

    if [[ "$host_string" == *"@"* ]]; then
        user="${host_string%@*}"
        host="${host_string#*@}"
    else
        host="$host_string"
    fi

    # Check for port in host:port format
    if [[ "$host" == *":"* ]]; then
        port="${host#*:}"
        host="${host%:*}"
    fi

    echo "$user" "$host" "$port"
}

# Send a VM to a remote host
cmd_send() {
    local vm_name=""
    local remote_host=""
    local ssh_port="22"

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--port)
                ssh_port="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$vm_name" ]]; then
                    vm_name="$1"
                elif [[ -z "$remote_host" ]]; then
                    remote_host="$1"
                else
                    log_error "Too many arguments"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$vm_name" || -z "$remote_host" ]]; then
        log_error "VM name and remote host required"
        echo "Usage: $SCRIPT_NAME send <vm-name> <user@host>"
        exit 1
    fi

    local vm_path="$MICROVM_BASE/$vm_name/persistent"
    local overlay_path
    overlay_path=$(get_overlay_path "$vm_name")
    local remote_base="$MICROVM_BASE/$vm_name"

    if ! vm_exists "$vm_name"; then
        log_error "VM does not exist: $vm_name"
        exit 1
    fi

    echo ""
    log_info "Sending MicroVM: $vm_name"
    log_info "Source: $vm_path"
    log_info "Destination: $remote_host:$remote_base"
    echo ""

    # Check if VM is running
    if vm_is_running "$vm_name"; then
        if [[ "$STOP_VM" == "true" ]]; then
            stop_vm "$vm_name"
        else
            log_warn "VM is running - data may be inconsistent"
            log_warn "Use --stop to stop the VM before transfer"
            echo ""
            read -r -p "Continue anyway? [y/N] " reply
            if [[ ! $reply =~ ^[Yy]$ ]]; then
                log_info "Aborted"
                exit 0
            fi
        fi
    fi

    # Build rsync options
    local rsync_opts=(-avz --progress --delete)
    rsync_opts+=(-e "ssh -p $ssh_port")

    if [[ "$DRY_RUN" == "true" ]]; then
        rsync_opts+=(--dry-run)
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        rsync_opts+=(-v)
    fi

    # Create remote directory
    log_info "Ensuring remote directory exists..."
    if [[ "$DRY_RUN" != "true" ]]; then
        # shellcheck disable=SC2029
        ssh -p "$ssh_port" "$remote_host" "sudo mkdir -p $remote_base/persistent && sudo chmod 0770 $remote_base/persistent"
    else
        log_info "[DRY-RUN] Would create: $remote_host:$remote_base/persistent"
    fi

    # Transfer persistent data
    log_info "Transferring persistent data..."
    log_verbose "rsync ${rsync_opts[*]} $vm_path/ $remote_host:$remote_base/persistent/"

    rsync "${rsync_opts[@]}" "$vm_path/" "$remote_host:$remote_base/persistent/"

    if [[ "$DRY_RUN" != "true" ]]; then
        log_success "Persistent data transferred"
    fi

    # Optionally transfer overlay
    if [[ "$INCLUDE_OVERLAY" == "true" ]]; then
        if [[ -f "$overlay_path" ]]; then
            local remote_overlay="/var/lib/microvms/$vm_name"

            log_info "Transferring overlay image..."

            # Create remote overlay directory
            if [[ "$DRY_RUN" != "true" ]]; then
                # shellcheck disable=SC2029
                ssh -p "$ssh_port" "$remote_host" "sudo mkdir -p $remote_overlay"
            fi

            log_verbose "rsync ${rsync_opts[*]} $overlay_path $remote_host:$remote_overlay/"

            rsync "${rsync_opts[@]}" "$overlay_path" "$remote_host:$remote_overlay/"

            if [[ "$DRY_RUN" != "true" ]]; then
                log_success "Overlay image transferred"
            fi
        else
            log_warn "Overlay image not found, skipping: $overlay_path"
        fi
    fi

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Transfer simulation complete"
    else
        log_success "Transfer complete!"
        echo ""
        echo "Next steps on $remote_host:"
        echo "  1. Ensure the MicroVM is defined in NixOS configuration"
        echo "  2. Rebuild the system: nixos-rebuild switch"
        echo "  3. Start the VM: systemctl start microvm@$vm_name"
    fi
}

# Receive a VM from a remote host
cmd_receive() {
    local remote_host=""
    local vm_name=""
    local ssh_port="22"

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--port)
                ssh_port="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$remote_host" ]]; then
                    remote_host="$1"
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

    if [[ -z "$remote_host" || -z "$vm_name" ]]; then
        log_error "Remote host and VM name required"
        echo "Usage: $SCRIPT_NAME receive <user@host> <vm-name>"
        exit 1
    fi

    local vm_path="$MICROVM_BASE/$vm_name/persistent"
    local overlay_path
    overlay_path=$(get_overlay_path "$vm_name")
    local remote_base="$MICROVM_BASE/$vm_name"

    echo ""
    log_info "Receiving MicroVM: $vm_name"
    log_info "Source: $remote_host:$remote_base"
    log_info "Destination: $vm_path"
    echo ""

    # Check if local VM is running
    if vm_is_running "$vm_name"; then
        if [[ "$STOP_VM" == "true" ]]; then
            stop_vm "$vm_name"
        else
            log_error "Local VM is running. Stop it first or use --stop"
            exit 1
        fi
    fi

    # Create local directory
    if [[ "$DRY_RUN" != "true" ]]; then
        log_info "Ensuring local directory exists: $vm_path"
        sudo mkdir -p "$vm_path"
    fi

    # Build rsync options
    local rsync_opts=(-avz --progress)
    rsync_opts+=(-e "ssh -p $ssh_port")

    if [[ "$DRY_RUN" == "true" ]]; then
        rsync_opts+=(--dry-run)
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        rsync_opts+=(-v)
    fi

    # Receive persistent data
    log_info "Receiving persistent data..."
    log_verbose "rsync ${rsync_opts[*]} $remote_host:$remote_base/persistent/ $vm_path/"

    rsync "${rsync_opts[@]}" "$remote_host:$remote_base/persistent/" "$vm_path/"

    if [[ "$DRY_RUN" != "true" ]]; then
        log_success "Persistent data received"

        # Fix permissions
        log_info "Fixing permissions..."
        sudo chown -R root:root "$vm_path"
        sudo chmod 0770 "$vm_path"
    fi

    # Optionally receive overlay
    if [[ "$INCLUDE_OVERLAY" == "true" ]]; then
        local remote_overlay="/var/lib/microvms/$vm_name/nix-store-overlay.img"
        local local_overlay_dir
        local_overlay_dir=$(dirname "$overlay_path")

        log_info "Receiving overlay image..."

        if [[ "$DRY_RUN" != "true" ]]; then
            sudo mkdir -p "$local_overlay_dir"
        fi

        log_verbose "rsync ${rsync_opts[*]} $remote_host:$remote_overlay $overlay_path"

        rsync "${rsync_opts[@]}" "$remote_host:$remote_overlay" "$overlay_path" || \
            log_warn "Overlay image not found on remote, skipping"

        if [[ "$DRY_RUN" != "true" && -f "$overlay_path" ]]; then
            log_success "Overlay image received"
        fi
    fi

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Receive simulation complete"
    else
        log_success "Receive complete!"
        echo ""
        echo "Next steps:"
        echo "  1. Ensure the MicroVM is defined in NixOS configuration"
        echo "  2. Rebuild the system: nixos-rebuild switch"
        echo "  3. Start the VM: systemctl start microvm@$vm_name"
    fi
}

# Bidirectional sync (dangerous)
cmd_sync() {
    log_error "Bidirectional sync is dangerous and not implemented"
    log_info "Use 'send' or 'receive' instead for explicit direction"
    exit 1
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
            -s|--stop)
                STOP_VM=true
                shift
                ;;
            -b|--base)
                MICROVM_BASE="$2"
                shift 2
                ;;
            -p|--port)
                SSH_PORT="$2"
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
        send)
            cmd_send "$@"
            ;;
        receive)
            cmd_receive "$@"
            ;;
        sync)
            cmd_sync "$@"
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
