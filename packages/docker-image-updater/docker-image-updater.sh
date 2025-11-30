#!/usr/bin/env bash
# docker-image-updater - Scan NixOS container configurations for Docker image updates
# Uses gum for beautiful interactive prompts

set -euo pipefail

# Default config path
CONFIG_PATH="${NIX_CONFIG_PATH:-$(pwd)}"

# Arrays to store image information
declare -A IMAGE_CURRENT
declare -A IMAGE_LATEST
declare -A UPDATES_AVAILABLE

# Parse command line arguments
show_help() {
    cat << EOF
docker-image-updater - Check for Docker image updates in NixOS configurations

Usage: docker-image-updater [OPTIONS]

Options:
    -p, --path PATH     Path to nix-config directory (default: current directory)
    -H, --host HOST     Only check containers for a specific host
    -l, --limit N       Limit the number of containers to check
    -h, --help          Show this help message
    --non-interactive   Run in non-interactive mode (just show updates)
    --dry-run           Only scan containers, skip checking for updates

Environment Variables:
    NIX_CONFIG_PATH     Alternative way to set the config path

Examples:
    docker-image-updater
    docker-image-updater --path /path/to/nix-config
    docker-image-updater --host monolith
    docker-image-updater --limit 10
    docker-image-updater --host monolith --limit 5
    docker-image-updater --non-interactive
    docker-image-updater --dry-run
EOF
}

NON_INTERACTIVE=false
HOST_FILTER=""
LIMIT=0
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--path)
            CONFIG_PATH="$2"
            shift 2
            ;;
        -H|--host)
            HOST_FILTER="$2"
            shift 2
            ;;
        -l|--limit)
            LIMIT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Verify config path exists
if [[ ! -d "$CONFIG_PATH" ]]; then
    gum style --foreground 1 "Error: Config path does not exist: $CONFIG_PATH"
    exit 1
fi

# Normalize image reference to full form
normalize_image() {
    local image="$1"

    # Already has registry
    if [[ "$image" == *"/"*"/"* ]] || [[ "$image" == *"."*"/"* ]]; then
        echo "$image"
        return
    fi

    # Docker Hub official images (no slash)
    if [[ "$image" != *"/"* ]]; then
        echo "docker.io/library/$image"
        return
    fi

    # Docker Hub user images (one slash, no dots before first slash)
    local prefix="${image%%/*}"
    if [[ "$prefix" != *"."* ]]; then
        echo "docker.io/$image"
        return
    fi

    echo "$image"
}

# Extract tag from image reference
get_tag() {
    local image="$1"
    if [[ "$image" == *":"* ]]; then
        echo "${image##*:}"
    else
        echo "latest"
    fi
}

# Extract image without tag
get_image_without_tag() {
    local image="$1"
    if [[ "$image" == *":"* ]]; then
        echo "${image%:*}"
    else
        echo "$image"
    fi
}

# Check if a tag is pinned (not floating)
is_pinned_tag() {
    local tag="$1"
    # Tags that are considered "floating" (not pinned)
    case "$tag" in
        latest|stable|release|main|master|develop|dev)
            return 1
            ;;
        *)
            # If tag contains only a major version like "2" or "v2", it's floating
            if [[ "$tag" =~ ^v?[0-9]+$ ]]; then
                return 1
            fi
            # If tag is like "2.1" without patch, could be floating
            # But we'll consider it pinned enough
            return 0
            ;;
    esac
}

# Get the latest tag for an image using various methods
get_latest_version() {
    local image="$1"
    local current_tag="$2"
    local normalized
    normalized=$(normalize_image "$image")
    local image_without_tag
    image_without_tag=$(get_image_without_tag "$normalized")

    # Try to get latest tag using skopeo
    local result=""

    # For images with version-like tags, try to find newer versions
    if [[ "$current_tag" =~ ^v?[0-9]+\.[0-9]+ ]]; then
        # Try to list tags and find the latest matching pattern
        local tags
        if tags=$(skopeo list-tags "docker://$image_without_tag" 2>/dev/null); then
            # Extract version-like tags and sort them
            local latest_tag
            latest_tag=$(echo "$tags" | jq -r '.Tags[]' 2>/dev/null | \
                grep -E "^v?[0-9]+\.[0-9]+(\.[0-9]+)?$" | \
                sort -V | tail -1 || true)

            if [[ -n "$latest_tag" ]]; then
                result="$latest_tag"
            fi
        fi
    fi

    # If we couldn't find a versioned tag, check if there's a digest difference
    if [[ -z "$result" ]]; then
        # Get current digest
        local current_digest latest_digest
        current_digest=$(skopeo inspect "docker://$normalized" 2>/dev/null | jq -r '.Digest' 2>/dev/null || echo "")

        # For floating tags, check if the latest has a different digest
        if ! is_pinned_tag "$current_tag"; then
            latest_digest=$(skopeo inspect "docker://$image_without_tag:latest" 2>/dev/null | jq -r '.Digest' 2>/dev/null || echo "")

            if [[ -n "$current_digest" ]] && [[ -n "$latest_digest" ]] && [[ "$current_digest" != "$latest_digest" ]]; then
                result="latest (new digest)"
            fi
        fi
    fi

    echo "$result"
}

# Compare versions - returns 0 (true) if v1 < v2
version_gt() {
    local v1="$1" v2="$2"
    # Remove 'v' prefix if present
    v1="${v1#v}"
    v2="${v2#v}"

    # Use sort -V to compare - if v2 comes last, v2 > v1
    [[ "$(printf '%s\n%s' "$v1" "$v2" | sort -V | tail -1)" == "$v2" ]] && [[ "$v1" != "$v2" ]]
}

# Scan container files using grep to find image definitions
scan_containers() {
    gum spin --spinner dot --title "Scanning container configurations..." -- sleep 0.5

    local container_files
    if [[ -n "$HOST_FILTER" ]]; then
        # Only scan the specified host
        local host_file="$CONFIG_PATH/hosts/$HOST_FILTER/containers.nix"
        if [[ -f "$host_file" ]]; then
            container_files="$host_file"
        else
            gum style --foreground 1 "Error: No containers.nix found for host: $HOST_FILTER"
            gum style --foreground 3 "Available hosts:"
            find "$CONFIG_PATH/hosts" -name "containers.nix" -print0 | xargs -0 -I{} dirname {} | xargs -I{} basename {} | sort | sed 's/^/  /'
            exit 1
        fi
    else
        container_files=$(find "$CONFIG_PATH/hosts" -name "containers.nix" 2>/dev/null || true)
    fi

    if [[ -z "$container_files" ]]; then
        gum style --foreground 3 "No container files found in $CONFIG_PATH/hosts"
        exit 0
    fi

    local total_containers=0
    local host_count=0

    while IFS= read -r file; do
        local host_name
        host_name=$(basename "$(dirname "$file")")
        host_count=$((host_count + 1))

        # Use awk to extract container name and image pairs
        # This handles nested braces properly
        while IFS='|' read -r container_name image; do
            if [[ -n "$container_name" ]] && [[ -n "$image" ]]; then
                local key="${host_name}:${container_name}"
                IMAGE_CURRENT["$key"]="$image"
                total_containers=$((total_containers + 1))
            fi
        done < <(awk '
            /^[[:space:]]*containers[[:space:]]*=[[:space:]]*\{/ { in_containers = 1; next }
            in_containers && /^[[:space:]]*\};[[:space:]]*$/ && depth == 0 { in_containers = 0; next }
            in_containers {
                # Count braces
                n = gsub(/{/, "{")
                depth += n
                n = gsub(/}/, "}")
                depth -= n

                # Look for container definition start: name = {
                if (match($0, /^[[:space:]]*(["a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*\{/, arr)) {
                    current = arr[1]
                    gsub(/"/, "", current)
                    container_depth = depth
                }

                # Look for image definition
                if (current != "" && match($0, /image[[:space:]]*=[[:space:]]*"([^"]+)"/, arr)) {
                    print current "|" arr[1]
                    current = ""
                }

                # Reset when container block ends
                if (current != "" && depth < container_depth) {
                    current = ""
                }
            }
        ' "$file")
    done <<< "$container_files"

    if [[ -n "$HOST_FILTER" ]]; then
        gum style --foreground 2 "Found $total_containers containers for host '$HOST_FILTER'"
    else
        gum style --foreground 2 "Found $total_containers containers across $host_count hosts"
    fi
}

# Check for updates
check_updates() {
    local total=${#IMAGE_CURRENT[@]}
    local checked=0
    local updates_found=0

    if [[ $total -eq 0 ]]; then
        gum style --foreground 3 "No containers found to check"
        exit 0
    fi

    # Apply limit if set
    local check_total=$total
    if [[ $LIMIT -gt 0 ]] && [[ $LIMIT -lt $total ]]; then
        check_total=$LIMIT
        gum style --foreground 3 "Limiting check to $LIMIT of $total containers"
    fi

    echo ""
    gum style --foreground 4 --bold "Checking for updates..."
    echo ""

    for key in "${!IMAGE_CURRENT[@]}"; do
        # Stop if we've reached the limit
        if [[ $LIMIT -gt 0 ]] && [[ $checked -ge $LIMIT ]]; then
            break
        fi

        checked=$((checked + 1))
        local image="${IMAGE_CURRENT[$key]}"
        local tag
        tag=$(get_tag "$image")
        local host="${key%%:*}"
        local container="${key#*:}"

        printf "\r[%d/%d] Checking %s/%s...                    " "$checked" "$check_total" "$host" "$container"

        local latest
        latest=$(get_latest_version "$image" "$tag" 2>/dev/null || echo "")

        if [[ -n "$latest" ]] && [[ "$latest" != "$tag" ]]; then
            if [[ "$latest" == "latest (new digest)" ]] || version_gt "$tag" "$latest"; then
                IMAGE_LATEST["$key"]="$latest"
                UPDATES_AVAILABLE["$key"]=1
                updates_found=$((updates_found + 1))
            fi
        fi
    done

    printf "\r%-80s\r" ""  # Clear line

    if [[ $updates_found -eq 0 ]]; then
        gum style --foreground 2 --bold "All $checked checked images are up to date!"
        exit 0
    fi

    gum style --foreground 3 --bold "Found $updates_found available updates (checked $checked containers)"
}

# Display updates in a table
display_updates() {
    echo ""

    # Check if we have a TTY for gum styling
    if [[ -t 1 ]]; then
        gum style --border normal --padding "0 1" --border-foreground 4 "Available Updates"
        echo ""

        # Build table data
        local headers="HOST,CONTAINER,CURRENT,LATEST"
        local rows=""

        for key in "${!UPDATES_AVAILABLE[@]}"; do
            local host="${key%%:*}"
            local container="${key#*:}"
            local current="${IMAGE_CURRENT[$key]}"
            local current_tag
            current_tag=$(get_tag "$current")
            local latest="${IMAGE_LATEST[$key]}"

            if [[ -n "$rows" ]]; then
                rows="$rows"$'\n'
            fi
            rows="$rows$host,$container,$current_tag,$latest"
        done

        echo "$headers"$'\n'"$rows" | gum table --border.foreground 4
    else
        # Fallback to simple text output when no TTY
        echo "=== Available Updates ==="
        echo ""
        printf "%-15s %-20s %-15s %-15s\n" "HOST" "CONTAINER" "CURRENT" "LATEST"
        printf "%-15s %-20s %-15s %-15s\n" "----" "---------" "-------" "------"

        for key in "${!UPDATES_AVAILABLE[@]}"; do
            local host="${key%%:*}"
            local container="${key#*:}"
            local current="${IMAGE_CURRENT[$key]}"
            local current_tag
            current_tag=$(get_tag "$current")
            local latest="${IMAGE_LATEST[$key]}"

            printf "%-15s %-20s %-15s %-15s\n" "$host" "$container" "$current_tag" "$latest"
        done
        echo ""
    fi
}

# Generate nix update for an image
generate_nix_update() {
    local key="$1"
    local host="${key%%:*}"
    local container="${key#*:}"
    local current="${IMAGE_CURRENT[$key]}"
    local latest="${IMAGE_LATEST[$key]}"

    local current_tag
    current_tag=$(get_tag "$current")
    local image_base
    image_base=$(get_image_without_tag "$current")

    local new_image
    if [[ "$latest" == "latest (new digest)" ]]; then
        new_image="$current"  # Keep same tag, just pull to get new digest
    else
        new_image="$image_base:$latest"
    fi

    echo "Host: $host"
    echo "Container: $container"
    echo "Current: $current"
    echo "New: $new_image"
    echo "File: $CONFIG_PATH/hosts/$host/containers.nix"
    echo ""

    # Show the sed command to update
    local escaped_current escaped_new
    # shellcheck disable=SC2016
    escaped_current=$(printf '%s\n' "$current" | sed 's/[[\.*^$()+?{|]/\\&/g')
    # shellcheck disable=SC2016
    escaped_new=$(printf '%s\n' "$new_image" | sed 's/[&/\]/\\&/g')

    echo "To update manually:"
    echo "  sed -i 's|$escaped_current|$escaped_new|g' $CONFIG_PATH/hosts/$host/containers.nix"
}

# Apply update to a file
apply_update() {
    local key="$1"
    local host="${key%%:*}"
    local current="${IMAGE_CURRENT[$key]}"
    local latest="${IMAGE_LATEST[$key]}"

    local image_base
    image_base=$(get_image_without_tag "$current")

    local new_image
    if [[ "$latest" == "latest (new digest)" ]]; then
        return 0  # Can't update file for digest changes
    else
        new_image="$image_base:$latest"
    fi

    local file="$CONFIG_PATH/hosts/$host/containers.nix"

    if [[ -f "$file" ]]; then
        sed -i "s|$current|$new_image|g" "$file"
        return 0
    fi
    return 1
}

# Interactive update selection
interactive_update() {
    echo ""

    local choice
    choice=$(gum choose --header "What would you like to update?" \
        "All images" \
        "All images for a specific host" \
        "Individual images" \
        "Show update commands only" \
        "Exit")

    case "$choice" in
        "All images")
            update_all
            ;;
        "All images for a specific host")
            update_by_host
            ;;
        "Individual images")
            update_individual
            ;;
        "Show update commands only")
            show_commands
            ;;
        "Exit")
            exit 0
            ;;
    esac
}

# Update all images
update_all() {
    echo ""
    if ! gum confirm "Update all ${#UPDATES_AVAILABLE[@]} images?"; then
        return
    fi

    local updated=0
    local failed=0

    for key in "${!UPDATES_AVAILABLE[@]}"; do
        local host="${key%%:*}"
        local container="${key#*:}"
        local latest="${IMAGE_LATEST[$key]}"

        if [[ "$latest" == "latest (new digest)" ]]; then
            gum style --foreground 3 "Skipping $host/$container (floating tag, pull to update)"
            continue
        fi

        if apply_update "$key"; then
            gum style --foreground 2 "Updated $host/$container"
            updated=$((updated + 1))
        else
            gum style --foreground 1 "Failed to update $host/$container"
            failed=$((failed + 1))
        fi
    done

    echo ""
    gum style --foreground 2 --bold "Updated $updated images"
    if [[ $failed -gt 0 ]]; then
        gum style --foreground 1 "Failed: $failed"
    fi
}

# Update by host
update_by_host() {
    # Get unique hosts with updates
    local hosts=()
    local host_pattern
    for key in "${!UPDATES_AVAILABLE[@]}"; do
        local host="${key%%:*}"
        host_pattern=" ${host} "
        if [[ ! " ${hosts[*]} " =~ $host_pattern ]]; then
            hosts+=("$host")
        fi
    done

    if [[ ${#hosts[@]} -eq 0 ]]; then
        gum style --foreground 3 "No hosts with updates"
        return
    fi

    local selected_host
    selected_host=$(printf '%s\n' "${hosts[@]}" | gum choose --header "Select a host:")

    if [[ -z "$selected_host" ]]; then
        return
    fi

    local host_updates=()
    for key in "${!UPDATES_AVAILABLE[@]}"; do
        local host="${key%%:*}"
        if [[ "$host" == "$selected_host" ]]; then
            host_updates+=("$key")
        fi
    done

    echo ""
    gum style --foreground 4 "Updates for $selected_host:"
    for key in "${host_updates[@]}"; do
        local container="${key#*:}"
        local current="${IMAGE_CURRENT[$key]}"
        local current_tag
        current_tag=$(get_tag "$current")
        local latest="${IMAGE_LATEST[$key]}"
        echo "  $container: $current_tag -> $latest"
    done
    echo ""

    if ! gum confirm "Apply these updates?"; then
        return
    fi

    local updated=0
    for key in "${host_updates[@]}"; do
        local container="${key#*:}"
        local latest="${IMAGE_LATEST[$key]}"

        if [[ "$latest" == "latest (new digest)" ]]; then
            gum style --foreground 3 "Skipping $container (floating tag)"
            continue
        fi

        if apply_update "$key"; then
            gum style --foreground 2 "Updated $container"
            updated=$((updated + 1))
        fi
    done

    echo ""
    gum style --foreground 2 --bold "Updated $updated containers on $selected_host"
}

# Update individual images
update_individual() {
    # Build list of updates
    local options=()
    for key in "${!UPDATES_AVAILABLE[@]}"; do
        local host="${key%%:*}"
        local container="${key#*:}"
        local current="${IMAGE_CURRENT[$key]}"
        local current_tag
        current_tag=$(get_tag "$current")
        local latest="${IMAGE_LATEST[$key]}"
        options+=("$host/$container: $current_tag -> $latest")
    done

    local selected
    selected=$(printf '%s\n' "${options[@]}" | gum choose --no-limit --header "Select images to update (space to select, enter to confirm):")

    if [[ -z "$selected" ]]; then
        return
    fi

    local updated=0
    while IFS= read -r line; do
        # Extract host and container from selection
        local host_container="${line%%:*}"
        local host="${host_container%%/*}"
        local container="${host_container#*/}"
        local key="$host:$container"

        local latest="${IMAGE_LATEST[$key]}"

        if [[ "$latest" == "latest (new digest)" ]]; then
            gum style --foreground 3 "Skipping $host/$container (floating tag)"
            continue
        fi

        if apply_update "$key"; then
            gum style --foreground 2 "Updated $host/$container"
            updated=$((updated + 1))
        fi
    done <<< "$selected"

    echo ""
    gum style --foreground 2 --bold "Updated $updated images"
}

# Show update commands
show_commands() {
    echo ""
    gum style --border normal --padding "0 1" --border-foreground 4 "Update Commands"
    echo ""

    for key in "${!UPDATES_AVAILABLE[@]}"; do
        generate_nix_update "$key"
        echo "---"
    done
}

# Display discovered containers (for dry-run mode)
display_containers() {
    echo ""

    # Check if we have a TTY for gum styling
    if [[ -t 1 ]]; then
        gum style --border normal --padding "0 1" --border-foreground 4 "Discovered Containers"
        echo ""

        # Build table data
        local headers="HOST,CONTAINER,IMAGE,TAG"
        local rows=""

        for key in "${!IMAGE_CURRENT[@]}"; do
            local host="${key%%:*}"
            local container="${key#*:}"
            local image="${IMAGE_CURRENT[$key]}"
            local tag
            tag=$(get_tag "$image")
            local image_base
            image_base=$(get_image_without_tag "$image")

            if [[ -n "$rows" ]]; then
                rows="$rows"$'\n'
            fi
            rows="$rows$host,$container,$image_base,$tag"
        done

        echo "$headers"$'\n'"$rows" | gum table --border.foreground 4
    else
        # Fallback to simple text output when no TTY
        echo "=== Discovered Containers ==="
        echo ""
        printf "%-15s %-20s %-40s %-15s\n" "HOST" "CONTAINER" "IMAGE" "TAG"
        printf "%-15s %-20s %-40s %-15s\n" "----" "---------" "-----" "---"

        for key in "${!IMAGE_CURRENT[@]}"; do
            local host="${key%%:*}"
            local container="${key#*:}"
            local image="${IMAGE_CURRENT[$key]}"
            local tag
            tag=$(get_tag "$image")
            local image_base
            image_base=$(get_image_without_tag "$image")

            printf "%-15s %-20s %-40s %-15s\n" "$host" "$container" "$image_base" "$tag"
        done
        echo ""
    fi
}

# Main function
main() {
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "1 2" \
        'Docker Image Updater' 'for NixOS Configurations'

    scan_containers

    if [[ ${#IMAGE_CURRENT[@]} -eq 0 ]]; then
        gum style --foreground 3 "No containers found"
        exit 0
    fi

    # Dry-run mode: just show discovered containers and exit
    if $DRY_RUN; then
        display_containers
        exit 0
    fi

    check_updates

    if [[ ${#UPDATES_AVAILABLE[@]} -eq 0 ]]; then
        exit 0
    fi

    display_updates

    if $NON_INTERACTIVE; then
        echo ""
        show_commands
    else
        interactive_update
    fi
}

main
