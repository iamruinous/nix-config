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
    # this system has a battery
    starship.battery.enable = true;
    tmux.powerkit.extraPlugins = ["battery"];

    # Raycast script commands
    raycast.enable = true;

    # Syncthing for cross-machine sync
    syncthing = {
      enable = true;
      claudeSessions.enable = false;
      devices = {
        jmacmini = {
          id = "SG7DSAA-HQVGRUF-PO5AKJV-QZSE5GD-PYARYJW-VL7CN3R-U6NJO22-X4ZPSQR";
        };
      };
    };

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

  # Budgey assistant session extractors (upstream module v0.16.0+)
  # Extracts sessions hourly and pushes to shared git archive
  # Chassis handles enrichment and ingestion
  programs.budgey = {
    enable = true;
    package = flake.inputs.budgey-assistant-ingest-tools.packages.${pkgs.system}.all-tools;
    hostName = "jbookpro";

    archive = {
      mode = "git";
      git = {
        url = "ssh://git@forge.meskill.farm/iamruinous/assistant-session-archive.git";
        # Deploy key shared with chassis for non-interactive git operations
        sshKeyFile = config.age.secrets.budgey_deploy_key.path;
      };
    };

    git = {
      autoCommit = true;
      autoPush = true;
    };

    services = {
      enable = true;
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

  # Budgey deploy key for git archive push (shared with chassis)
  age.secrets.budgey_deploy_key = {
    rekeyFile = flake + /files/configs/budgey/deploy-key.age;
    path = "${config.home.homeDirectory}/.local/share/budgey/deploy-key";
    mode = "400";
  };

  home.stateVersion = "26.05";
}
