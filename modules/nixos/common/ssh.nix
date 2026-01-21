{lib, ...}: {
  # OpenSSH daemon
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      # Security hardening
      PasswordAuthentication = lib.mkDefault false;
      PermitRootLogin = lib.mkDefault "prohibit-password";
      KbdInteractiveAuthentication = lib.mkDefault false;
      # Accept BYPASS_LOGIN_HUB env var from clients (for remote-rebuild, etc.)
      # Also accept standard locale vars
      AcceptEnv = ["BYPASS_LOGIN_HUB" "LANG" "LC_*"];
    };
    extraConfig = ''
      Match User jmeskill
            AllowAgentForwarding yes
            AllowTcpForwarding yes
            PermitTTY yes
            PermitTunnel yes
            X11Forwarding yes
      Match All
    ''; # TODO: generalize user
  };
}
