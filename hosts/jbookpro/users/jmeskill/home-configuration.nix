{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.darwin
  ];

  # Enable todoist
  ruinous.todoist.sync.enable = true;

  # Enable vdirsyncer
  ruinous.vdirsyncer.sync.enable = true;

  # Ensure homebrew is in the PATH
  home.sessionPath = [
    "/opt/homebrew/bin/"
  ];

  # this system has a battery
  ruinous.starship.battery.enable = true;

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

  programs.wezterm.enable = true;
  ruinous.openssh.remote.forwarding.enable = true;

  home.stateVersion = "25.05";
}
