{pkgs, ...}: let
  ssh-agent-check = pkgs.writeShellApplication {
    name = "ssh-agent-check";

    runtimeInputs = [pkgs.openssh];

    text = builtins.readFile ./ssh-agent-check.sh;
  };

  ssh-agent-refresh = pkgs.writeShellApplication {
    name = "ssh-agent-refresh";

    runtimeInputs = [pkgs.tmux];

    text = builtins.readFile ./ssh-agent-refresh.sh;
  };

  # Combine both scripts into a single package
  combined = pkgs.symlinkJoin {
    name = "ssh-agent-check";
    paths = [ssh-agent-check ssh-agent-refresh];

    meta = {
      description = "SSH agent utilities: check availability and refresh across tmux panes";
      mainProgram = "ssh-agent-check";
    };
  };
in
  combined
  // {
    passthru.tests = {
      # Test that script exits 0 when SSH_TTY is not set (local session)
      local-session = pkgs.runCommand "test-ssh-agent-check-local" {} ''
        unset SSH_TTY
        unset SSH_AUTH_SOCK
        if ${ssh-agent-check}/bin/ssh-agent-check; then
          echo "PASS: Returns 0 when SSH_TTY is not set" > $out
        else
          echo "FAIL: Should return 0 when SSH_TTY is not set (local session)"
          exit 1
        fi
      '';

      # Test that ssh-agent-refresh shows help
      refresh-help = pkgs.runCommand "test-ssh-agent-refresh-help" {} ''
        ${ssh-agent-refresh}/bin/ssh-agent-refresh --help > $out
        grep -q "ssh-agent-refresh" $out
      '';
    };
  }
