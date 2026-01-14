{flake, ...}: {
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

  home.stateVersion = "26.05";
}
