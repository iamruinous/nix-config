{pkgs, ...}:
pkgs.writeShellApplication {
  name = "eztunnel";

  runtimeInputs = [pkgs.openssh];

  text = ''
    #!/usr/bin/env bash
    #
    # tunnel.sh - Simple SSH local tunnel
    #
    # Creates an SSH local tunnel to access a remote port from localhost.
    #
    # Usage:
    #   eztunnel <remote-host> [remote-port] [local-port]
    #
    # Arguments:
    #   remote-host   Remote server hostname (required)
    #   remote-port   Port on remote server (default: 8765)
    #   local-port    Local port to bind (default: same as remote-port)
    #
    # Examples:
    #   eztunnel zenith              # Access zenith:8765 via localhost:8765
    #   eztunnel zenith 9000         # Access zenith:9000 via localhost:9000
    #   eztunnel zenith 9000 3000    # Access zenith:9000 via localhost:3000
    #

    set -euo pipefail

    if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        sed -n '/^# Usage:/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \?//'
        exit 0
    fi

    REMOTE_HOST="$1"
    REMOTE_PORT="''${2:-8765}"
    LOCAL_PORT="''${3:-$REMOTE_PORT}"

    echo "Creating tunnel: localhost:''${LOCAL_PORT} -> ''${REMOTE_HOST}:''${REMOTE_PORT}"
    echo "Press Ctrl+C to stop"
    echo ""

    ssh -o StrictHostKeyChecking=accept-new \
        -o ServerAliveInterval=30 \
        -o ServerAliveCountMax=3 \
        -L "''${LOCAL_PORT}:localhost:''${REMOTE_PORT}" \
        -N \
        "''${REMOTE_HOST}"
  '';

  meta = {
    description = "Simple SSH local tunnel utility for accessing remote ports via localhost";
    homepage = "https://github.com/iamruinous/nix-config";
    license = pkgs.lib.licenses.mit;
    maintainers = [];
    mainProgram = "eztunnel";
    platforms = pkgs.lib.platforms.unix;
  };
}
