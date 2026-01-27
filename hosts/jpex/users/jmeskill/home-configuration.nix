{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.darwin
  ];

  ruinous = {
    # Enable rust-motd for system info on login
    rust-motd.enable = true;

    # Enable todoist
    todoist.enable = true;

    # Enable vdirsyncer
    vdirsyncer.enable = true;

    # ssh agent forwarding
    openssh.remote.forwarding.enable = true;

    homebrew.onActivation.cleanup = "none";

    # enable opencode with default configuration
    ruinage = {
      enable = true;

      # Global OpenCode configuration
      assistants.opencode = {
        enable = true;
        # model, plugins, mcpServers, providers inherited from defaults
        harnesses.ruinagents.enable = true;
      };

      # Global Claude Code configuration
      assistants.claude-code = {
        enable = true;
        # model, plugins, mcpServers, providers inherited from defaults
        harnesses.ruinagents.enable = true;
      };

      # Global Codex configuration
      assistants.codex = {
        enable = true;
        # model, plugins, mcpServers, providers inherited from defaults
        harnesses.ruinagents.enable = true;
      };

      # Global Gemini configuration
      assistants.gemini = {
        enable = true;
        # model, plugins, mcpServers, providers inherited from defaults
        harnesses.ruinagents.enable = true;
      };
    };
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
