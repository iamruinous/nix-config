{pkgs, ...}: let
  script = pkgs.writeShellApplication {
    name = "ssh-agent-check";

    runtimeInputs = [pkgs.openssh];

    text = builtins.readFile ./ssh-agent-check.sh;

    meta = {
      description = "Check if SSH agent is available and responding";
      mainProgram = "ssh-agent-check";
    };
  };
in
  script
  // {
    passthru.tests = {
      # Test that script exits 0 when SSH_TTY is not set (local session)
      local-session = pkgs.runCommand "test-ssh-agent-check-local" {} ''
        unset SSH_TTY
        unset SSH_AUTH_SOCK
        if ${script}/bin/ssh-agent-check; then
          echo "PASS: Returns 0 when SSH_TTY is not set" > $out
        else
          echo "FAIL: Should return 0 when SSH_TTY is not set (local session)"
          exit 1
        fi
      '';
    };
  }
