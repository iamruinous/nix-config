{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.darwin
  ];

  # Enable rust-motd for system info on login
  ruinous.rust-motd.enable = true;

  # Enable todoist
  ruinous.todoist.sync.enable = true;

  # Enable vdirsyncer
  ruinous.vdirsyncer.sync.enable = true;

  # Ensure homebrew is in the PATH
  home.sessionPath = [
    "/usr/local/homebrew/bin/"
  ];
  home.uid = 502;

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

  programs.wezterm.enable = true;
  ruinous.openssh.remote.forwarding.enable = true;

  home.stateVersion = "26.05";
}
