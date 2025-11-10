{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.forgejo-shell
    pkgs.messy-restricted-shell
  ];

  users.users.git.shell = pkgs.forgejo-shell;
  users.users.git.extraGroups = ["docker"];

  # users.users.messy.shell = pkgs.messy-restricted-shell;
  users.users.messy.extraGroups = ["docker"];
  users.users.messy.openssh.authorizedKeys.keys = [
    "no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty,command=\"${pkgs.messy-restricted-shell}/bin/messy-restricted-shell\" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHrfqbC3NHGjwLhV4qoBCWZ44DU7dfyhUJJ83XCD1LD  messy@messy-tty"
  ];

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
