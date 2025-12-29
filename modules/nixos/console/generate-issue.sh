#!/usr/bin/env bash
# Generate dynamic /etc/issue with system info
# Displays system information at the login prompt (before login)

set -euo pipefail

# Colors (ANSI escape codes that work in /etc/issue)
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
BLUE="\e[34m"
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
WHITE="\e[37m"

# Get system info
HOSTNAME=$(@hostname@/bin/hostname)
KERNEL=$(@coreutils@/bin/uname -r)
ARCH=$(@coreutils@/bin/uname -m)
UPTIME=$(@coreutils@/bin/uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")

# Get IP addresses (excluding loopback)
IPS=$(@iproute2@/bin/ip -4 addr show scope global 2>/dev/null | @gawk@/bin/awk '/inet / {split($2,a,"/"); printf "%s ", a[1]}' || echo "")
IP6S=$(@iproute2@/bin/ip -6 addr show scope global 2>/dev/null | @gawk@/bin/awk '/inet6 / {split($2,a,"/"); printf "%s ", a[1]}' | head -c 50 || echo "")

# Memory info
MEM_TOTAL=$(@procps@/bin/free -h | @gawk@/bin/awk '/^Mem:/ {print $2}')
MEM_USED=$(@procps@/bin/free -h | @gawk@/bin/awk '/^Mem:/ {print $3}')
MEM_PERCENT=$(@procps@/bin/free | @gawk@/bin/awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

# Disk info (root filesystem)
DISK_TOTAL=$(@coreutils@/bin/df -h / | @gawk@/bin/awk 'NR==2 {print $2}')
DISK_USED=$(@coreutils@/bin/df -h / | @gawk@/bin/awk 'NR==2 {print $3}')
DISK_PERCENT=$(@coreutils@/bin/df / | @gawk@/bin/awk 'NR==2 {gsub(/%/,""); print $5}')

# Load average
LOAD=$(@coreutils@/bin/cat /proc/loadavg | @coreutils@/bin/cut -d' ' -f1-3)

# CPU count
CPU_COUNT=$(@coreutils@/bin/nproc)

# Current time
DATE=$(@coreutils@/bin/date '+%Y-%m-%d %H:%M:%S %Z')

# Generate issue file
cat > /etc/issue << EOF
${RESET}
${BOLD}${BLUE}  _   _ _       ___  ____  ${RESET}
${BOLD}${BLUE} | \ | (_)_  __/ _ \/ ___| ${RESET}
${BOLD}${BLUE} |  \| | \ \/ / | | \___ \ ${RESET}
${BOLD}${BLUE} | |\  | |>  <| |_| |___) |${RESET}
${BOLD}${BLUE} |_| \_|_/_/\_\\___/|____/ ${RESET}
${RESET}
${BOLD}${WHITE}  $HOSTNAME${RESET}${DIM} @ \l${RESET}
${DIM}──────────────────────────────────────${RESET}
${CYAN}  Kernel:${RESET}  $KERNEL ($ARCH)
${CYAN}  Uptime:${RESET}  $UPTIME
${CYAN}  Load:${RESET}    $LOAD ($CPU_COUNT cores)
${DIM}──────────────────────────────────────${RESET}
${GREEN}  Memory:${RESET}  $MEM_USED / $MEM_TOTAL (${MEM_PERCENT}%)
${GREEN}  Disk /:${RESET}  $DISK_USED / $DISK_TOTAL (${DISK_PERCENT}%)
${DIM}──────────────────────────────────────${RESET}
${YELLOW}  IPv4:${RESET}    $IPS
${DIM}──────────────────────────────────────${RESET}
${DIM}  $DATE${RESET}

EOF
