{pkgs, ...}:
pkgs.writeShellApplication {
  name = "ssh-agent-check";

  runtimeInputs = [pkgs.openssh];

  text = ''
    # Check if SSH agent is available and responding
    # Exit codes:
    #   0 - Agent is working (has keys or no keys but reachable)
    #   1 - Agent is not responding (SSH_AUTH_SOCK invalid or agent dead)
    #
    # Caching: Results are cached based on SSH_AUTH_SOCK value
    # Only re-checks if SSH_AUTH_SOCK has changed

    CACHE_FILE="''${XDG_RUNTIME_DIR:-/tmp}/ssh-agent-check-cache-$$"

    # If SSH_AUTH_SOCK is not set, agent is not available
    if [ -z "$SSH_AUTH_SOCK" ]; then
      exit 1
    fi

    # Check if we have a cached result for this SSH_AUTH_SOCK
    if [ -f "$CACHE_FILE" ]; then
      read -r cached_sock cached_result < "$CACHE_FILE" 2>/dev/null || true

      # If SSH_AUTH_SOCK hasn't changed, return cached result
      if [ "$cached_sock" = "$SSH_AUTH_SOCK" ]; then
        exit "$cached_result"
      fi
    fi

    # Try to contact the agent with ssh-add -L
    # Exit codes from ssh-add:
    #   0 - Agent has identities
    #   1 - Agent reachable but no identities
    #   2 - Cannot contact agent
    ssh-add -L >/dev/null 2>&1
    exit_code=$?

    # Agent is working if exit code is 0 or 1
    # Agent is broken if exit code is 2
    if [ "$exit_code" -eq 2 ]; then
      result=1
    else
      result=0
    fi

    # Cache the result
    echo "$SSH_AUTH_SOCK $result" > "$CACHE_FILE"

    exit "$result"
  '';

  meta = {
    description = "Check if SSH agent is available and responding";
    mainProgram = "ssh-agent-check";
  };
}
