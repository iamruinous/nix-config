{
  config,
  flake,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.darwin
    # Upstream budgey home-manager module (v0.16.0+ with launchd support)
    flake.inputs.budgey-assistant-ingest-tools.homeManagerModules.default
  ];

  ruinous = {
    # Enable rust-motd for system info on login
    rust-motd.enable = true;

    # ssh agent forwarding
    openssh.remote.forwarding.enable = true;
  };

  # Ensure homebrew is in the PATH
  home.sessionPath = [
    "/opt/homebrew/bin/"
  ];
  home.uid = 502;

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

  programs.wezterm.enable = true;

  home.stateVersion = "26.05";
}
