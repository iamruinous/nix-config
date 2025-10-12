{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.darwin
  ];

  # Enable todoist
  services.todoist-auto.enable = true;

  # Enable vdirsyncer
  services.vdirsyncer-auto.enable = true;

  # Ensure homebrew is in the PATH
  home.sessionPath = [
    "/usr/local/homebrew/bin/"
  ];

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

  programs.wezterm.enable = true;

  home.stateVersion = "25.05";
}
