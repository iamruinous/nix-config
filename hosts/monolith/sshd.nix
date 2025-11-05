{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.forgejo-shell
  ];

  users.users.git.shell = pkgs.forgejo-shell;
  users.users.git.extraGroups = ["docker"];

  security.sudo.extraRules = [
    {
      users = ["git"];
      commands = [
        {
          command = "${pkgs.docker}/bin/docker";
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
