{lib, ...}: {
  # OpenSSH daemon
  services.openssh.enable = lib.mkDefault true;
  services.openssh.extraConfig = ''
    Match User jmeskill
          AllowAgentForwarding yes
          AllowTcpForwarding yes
          PermitTTY yes
          PermitTunnel yes
          X11Forwarding yes
    Match All
  ''; # TODO: generalize user
}
