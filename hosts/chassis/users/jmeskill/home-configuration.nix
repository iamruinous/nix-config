{
  flake,
  config,
  ...
}: {
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
          {name = "top"; command = "btop";}
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
      # Projects with caddy.fqdn get:
      #   - Systemd user service (opencode web)
      #   - Caddy route (configured in chassis/caddy.nix)
      #   - CORS configured for the FQDN
      #   - tmuxp session in attach mode (no server window)
      opencode-projects = {
        enable = true;

        environmentFiles = [
          config.age.secrets.chassis_opencode_env.path
        ];

        projects = {
          # nix-config - web service with Caddy
          nix = {
            workdir = "/home/jmeskill/Projects/github/iamruinous/nix-config";
            port = 9500;
            caddy.fqdn = "nix.oc.ruinous.ai";
          };

          # n8n-agent - web service with Caddy
          n8n = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/n8n-agent";
            port = 9501;
            caddy.fqdn = "n8n-agent.oc.ruinous.ai";
          };

          # dossiq-ai - web service with Caddy
          dossiq = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/dossiq-ai";
            port = 9502;
            caddy.fqdn = "dossiq.oc.ruinous.ai";
            tmuxp.extraWindows = [
              {
                name = "tests";
                command = "uv run ptw";
              }
            ];
          };

          # codey-agent-system - web service with Caddy
          codey = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/codey-agent-system";
            port = 9503;
            caddy.fqdn = "codey.oc.ruinous.ai";
          };

          # kimaki-discord-voice-bot - web service with Caddy
          kimaki-discord = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/kimaki-discord-voice-bot";
            port = 9504;
            caddy.fqdn = "kimaki-discord.oc.ruinous.ai";
          };

          # n8n-messy-discord-bot - web service with Caddy
          messy-discord = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/n8n-messy-discord-bot/";
            port = 9505;
            caddy.fqdn = "messy-bot.oc.ruinous.ai";
          };
        };
      };
    };
  };

  age.secrets.chassis_opencode_env = {
    rekeyFile = ./files/opencode/env.age;
    mode = "400";
  };

  home.stateVersion = "26.05";
}
