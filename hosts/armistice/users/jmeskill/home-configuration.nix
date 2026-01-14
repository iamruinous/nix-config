{
  flake,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.default
  ];

  ruinous = {
    rust-motd.enable = true;
    loginHub.enable = true;

    # Hub session - always running, for general use
    tmuxp = {
      enable = true;
      sessions.hub = {
        windows = [
          {name = "shell"; focus = true;}
          {name = "top"; command = "btop";}
          {name = "docker"; command = "sudo lazydocker";}
        ];
      };
    };
  };

  # systemd.user.tmpfiles.rules = [
  #   "L+    /home/jmeskill/.local/bin/op-ssh-sign -    -    -     - ${pkgs.openssh}/bin/ssh-keygen"
  # ];

  home.stateVersion = "26.05";
}
