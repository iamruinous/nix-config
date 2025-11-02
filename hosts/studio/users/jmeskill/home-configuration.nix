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
    "/usr/local/homebrew/bin/"
  ];

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

  programs.wezterm.enable = true;
  programs.ssh-interactive.enable = true;

  home.stateVersion = "25.05";
}
