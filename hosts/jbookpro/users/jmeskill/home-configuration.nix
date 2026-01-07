{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.darwin
  ];

  ruinous.git.signing.use1Password = true;

  # Enable rust-motd for system info on login
  ruinous.rust-motd.enable = true;

  # Enable todoist
  ruinous.todoist.enable = true;

  # Enable vdirsyncer
  ruinous.vdirsyncer.enable = true;

  # Ensure homebrew is in the PATH
  home.sessionPath = [
    "/opt/homebrew/bin/"
  ];
  home.uid = 501;

  # this system has a battery
  ruinous.starship.battery.enable = true;

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

  programs.wezterm.enable = true;
  ruinous.openssh.remote.forwarding.enable = true;

  home.stateVersion = "26.05";
}
