{flake, config, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.kde
  ];

  programs.wezterm.enable = true;

  ruinous = {
    rust-motd.enable = true;
    openssh.remote.forwarding.enable = true;
    loginHub.enable = true;

    git.default = {
      userEmail = "jade@ruinous.ai";
      signingKey = "/home/jmeskill/.ssh/id_codey_ed25519";
    };

    kde.enable = true;

    # Hub session - always running, for general use
    tmuxp = {
      enable = true;
      sessions.hub = {
        windows = [
          {name = "shell"; focus = true;}
        ];
      };
    };

    ai-cli = {
      opencode = {
        enable = true;
        configs.default.notifier.enable = false;
      };

      # Unified project-centric configuration
      opencode-projects = {
        enable = true;

        projects = {
          # nix-config
          nix = {
            workdir = "/home/jmeskill/Projects/github/iamruinous/nix-config";
            port = 9500;
          };

          # n8n-agent
          n8n = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/n8n-agent";
            port = 9501;
          };

          # dossiq-ai
          dossiq = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/dossiq-ai";
            port = 9502;
            tmuxp.extraWindows = [
              {name = "tests"; command = "uv run ptw";}
            ];
          };

          # codey-agent-system
          codey = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/codey-system-agent";
            port = 9503;
          };

          # kimaki-discord-voice-bot
          kimaki-discord = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/kimaki-discord-voice-bot";
            port = 9504;
          };
        };
      };
    };
  };

  home.stateVersion = "26.05";
}
