# Dynamic /etc/issue generator
# Displays system info at the login prompt (before login)
{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.ruinous.dynamicIssue;

  # Script to generate /etc/issue with system info
  generateIssue = pkgs.writeShellScript "generate-issue" ''
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
    HOSTNAME=$(${pkgs.hostname}/bin/hostname)
    KERNEL=$(${pkgs.coreutils}/bin/uname -r)
    ARCH=$(${pkgs.coreutils}/bin/uname -m)
    UPTIME=$(${pkgs.coreutils}/bin/uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")

    # Get IP addresses (excluding loopback)
    IPS=$(${pkgs.iproute2}/bin/ip -4 addr show scope global 2>/dev/null | ${pkgs.gawk}/bin/awk '/inet / {split($2,a,"/"); printf "%s ", a[1]}' || echo "")
    IP6S=$(${pkgs.iproute2}/bin/ip -6 addr show scope global 2>/dev/null | ${pkgs.gawk}/bin/awk '/inet6 / {split($2,a,"/"); printf "%s ", a[1]}' | head -c 50 || echo "")

    # Memory info
    MEM_TOTAL=$(${pkgs.procps}/bin/free -h | ${pkgs.gawk}/bin/awk '/^Mem:/ {print $2}')
    MEM_USED=$(${pkgs.procps}/bin/free -h | ${pkgs.gawk}/bin/awk '/^Mem:/ {print $3}')
    MEM_PERCENT=$(${pkgs.procps}/bin/free | ${pkgs.gawk}/bin/awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

    # Disk info (root filesystem)
    DISK_TOTAL=$(${pkgs.coreutils}/bin/df -h / | ${pkgs.gawk}/bin/awk 'NR==2 {print $2}')
    DISK_USED=$(${pkgs.coreutils}/bin/df -h / | ${pkgs.gawk}/bin/awk 'NR==2 {print $3}')
    DISK_PERCENT=$(${pkgs.coreutils}/bin/df / | ${pkgs.gawk}/bin/awk 'NR==2 {gsub(/%/,""); print $5}')

    # Load average
    LOAD=$(${pkgs.coreutils}/bin/cat /proc/loadavg | ${pkgs.coreutils}/bin/cut -d' ' -f1-3)

    # CPU count
    CPU_COUNT=$(${pkgs.coreutils}/bin/nproc)

    # Current time
    DATE=$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S %Z')

    # Generate issue file
    cat > /etc/issue << EOF
''${RESET}
''${BOLD}''${BLUE}  _   _ _       ___  ____  ''${RESET}
''${BOLD}''${BLUE} | \ | (_)_  __/ _ \/ ___| ''${RESET}
''${BOLD}''${BLUE} |  \| | \ \/ / | | \___ \ ''${RESET}
''${BOLD}''${BLUE} | |\  | |>  <| |_| |___) |''${RESET}
''${BOLD}''${BLUE} |_| \_|_/_/\_\\\\___/|____/ ''${RESET}
''${RESET}
''${BOLD}''${WHITE}  $HOSTNAME''${RESET}''${DIM} @ \l''${RESET}
''${DIM}──────────────────────────────────────''${RESET}
''${CYAN}  Kernel:''${RESET}  $KERNEL ($ARCH)
''${CYAN}  Uptime:''${RESET}  $UPTIME
''${CYAN}  Load:''${RESET}    $LOAD ($CPU_COUNT cores)
''${DIM}──────────────────────────────────────''${RESET}
''${GREEN}  Memory:''${RESET}  $MEM_USED / $MEM_TOTAL (''${MEM_PERCENT}%)
''${GREEN}  Disk /:''${RESET}  $DISK_USED / $DISK_TOTAL (''${DISK_PERCENT}%)
''${DIM}──────────────────────────────────────''${RESET}
''${YELLOW}  IPv4:''${RESET}    $IPS
''${DIM}──────────────────────────────────────''${RESET}
''${DIM}  $DATE''${RESET}

EOF
  '';
in {
  options.ruinous.dynamicIssue = {
    enable = lib.mkEnableOption "dynamic /etc/issue with system info";

    refreshInterval = lib.mkOption {
      type = lib.types.str;
      default = "*:0/5"; # Every 5 minutes
      description = "How often to regenerate the issue file (systemd OnCalendar format)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Don't let NixOS manage /etc/issue
    environment.etc."issue".enable = false;

    # Service to generate the issue file
    systemd.services.generate-issue = {
      description = "Generate dynamic /etc/issue";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = generateIssue;
        RemainAfterExit = false;
      };
    };

    # Timer to refresh periodically
    systemd.timers.generate-issue = {
      description = "Refresh /etc/issue periodically";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.refreshInterval;
        OnBootSec = "10s";
        Persistent = true;
      };
    };
  };
}
