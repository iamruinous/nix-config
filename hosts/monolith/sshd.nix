{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = [
    pkgs.forgejo-shell
  ];

  users.users.git.shell = pkgs.forgejo-shell;
  users.users.git.extraGroups = ["docker"];

  programs.rush.enable = true;
  # programs.rush.global = ''
  #   regex +extended +icase
  # '';

  programs.rush.rules = {
    "ls" = ''
      match $command == "/bin/ls"
      match $# = 2
    '';
    #
    # "docker_ps" = ''
    #   match[0] "^(/usr/bin/)?docker$"
    #   match[1] "^ps$"
    #   match $# = 2
    # '';
    #
    # "docker_ps_all" = ''
    #   match[0] "^(/usr/bin/)?docker$"
    #   match[1] "^ps$"
    #   match[2] "^-a$"
    #   match $# = 3
    # '';

    "default" = ''
      exit "Access denied: Only authorized commands allowed"
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

  security.sudo.extraRules = [
    {
      users = ["git"];
      commands = [
        {
          command = "${pkgs.docker}/bin/docker"; # TODO: need to limit this command
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  services.openssh.extraConfig = ''
    Match User git
      AuthorizedKeysCommandUser git
      AuthorizedKeysCommand ${pkgs.docker}/bin/docker exec -i forgejo /usr/local/bin/forgejo keys -c /data/gitea/conf/app.ini -e git -u %u -t %t -k %k
  '';
}
