{config, ...}: {
  programs.rush.enable = true;
  programs.rush.rules = {
    "change-command" = ''
      match $command == "ls -la"
      set [0] = "/bin/ls"
      set [1] = "-alF"
    '';
  };
  users.users.messy = {
    inherit (config.programs.rush) shell;
    extraGroups = ["docker"];
    # openssh.authorizedKeys.keyFiles = lib.mkOverride 50 [];
    # openssh.authorizedKeys.keys = [
    #   "no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,command=\"${pkgs.messy-restricted-shell}/bin/messy-restricted-shell\" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHrfqbC3NHGjwLhV4qoBCWZ44DU7dfyhUJJ83XCD1LD  messy@messy-tty"
    # ];
  };
}
