{
  config,
  flake,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.darwin
  ];

  ruinous = {
    # this system has a battery
    starship.battery.enable = true;
    tmux.powerkit.plugins = config.ruinous.tmux.powerkit.plugins ++ ["battery"];

    # allow use of 1password op-ssh-sign
    git.signing.use1Password = true;

    # Enable rust-motd for system info on login
    rust-motd.enable = true;

    # Enable todoist
    todoist.enable = true;

    # Enable vdirsyncer
    vdirsyncer.enable = true;

    # ssh agent forwarding
    openssh.remote.forwarding.enable = true;

    # enable opencode with my preferred plugins
    ai-cli.opencode.enable = true;
  };

  # Ensure homebrew is in the PATH
  home.sessionPath = [
    "/opt/homebrew/bin/"
  ];
  home.uid = 501;

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

  programs.wezterm.enable = true;

  home.stateVersion = "26.05";
}
