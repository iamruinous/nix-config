{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.darwin
  ];

  ruinous = {
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

    # enable opencode with default configuration
    ruinage.enable = true;
    ruinage.assistants.opencode.enable = true;

    # Budgey assistant session extractors
    # Extracts sessions hourly and pushes to shared git archive
    # Chassis handles enrichment and ingestion
    budgey-extractors = {
      enable = true;
      hostName = "jmacmini";
      git.url = "ssh://git@forge.meskill.farm/iamruinous/assistant-session-archive.git";
      # Uses SSH agent for authentication (no explicit key needed)
      extractors = {
        opencode.enable = true;
        claude.enable = true;
        codex.enable = true;
        gemini.enable = true;
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
