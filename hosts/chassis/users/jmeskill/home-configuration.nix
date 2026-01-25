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
          {
            name = "top";
            command = "btop";
          }
          {
            name = "shell";
            focus = true;
          }
        ];
      };
    };

    ai-cli = {
      opencode = {
        enable = true;
        sisyphusSignature = false;
        configs.default.notifier.enable = false;
      };

      # Kimaki Discord voice bot
      kimaki = {
        enable = true;
        configDir = "${config.home.homeDirectory}/.config/kimaki";
        cacheDir = "${config.home.homeDirectory}/.cache/kimaki";
        stateDir = "${config.home.homeDirectory}/.local/state/kimaki";
        dataDir = "${config.home.homeDirectory}/.local/share/kimaki";
        environmentFiles = [
          config.age.secrets.chassis_kimaki_env.path
        ];
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

          # ruinagents - web service with Caddy
          ruinagents = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/ruinagents";
            port = 9507;
            caddy.fqdn = "ruinagents.oc.ruinous.ai";
          };

          # budgey-extractor - web service with Caddy
          budgey-extractor = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/budgey-extractor";
            port = 9508;
            caddy.fqdn = "budgey-extractor.oc.ruinous.ai";
          };

          # budgey-dashboard - web service with Caddy
          budgey-dashboard = {
            workdir = "/home/jmeskill/Projects/farmforge/iamruinous/budgey-dashboard";
            port = 9509;
            caddy.fqdn = "budgey-dashboard.oc.ruinous.ai";
          };

          # kimaki - Discord bot (no web service, budgey tracking only)
          # Uses isolated XDG dirs managed by ruinous.ai-cli.kimaki module
          kimaki = {
            workdir = "${config.home.homeDirectory}/.kimaki";
            port = 9599; # Unused, required by schema
            budgey = {
              enable = true;
              tags = ["discord" "bot"];
              configDir = "${config.home.homeDirectory}/.config/kimaki";
              stateDir = "${config.home.homeDirectory}/.local/state/kimaki";
              dataDir = "${config.home.homeDirectory}/.local/share/kimaki";
            };
            # No web service or caddy for kimaki
            web.enable = false;
            tmuxp.enable = false;
          };
        };
      };

      # Scheduled ingestion of OpenCode session data into PostgreSQL and Weaviate
      # Uses TCP with password auth via environment file
      budgey-extractor = {
        enable = true;
        environmentFile = config.age.secrets.chassis_budgey_env.path;
        weaviate.enable = true; # Uses WEAVIATE_URL and WEAVIATE_API_KEY from environmentFile
      };
    };
  };

  age.secrets.chassis_opencode_env = {
    rekeyFile = ./files/opencode/env.age;
    mode = "400";
  };

  # Budgey database credentials (TCP with password auth)
  age.secrets.chassis_budgey_env = {
    rekeyFile = ./files/budgey/env.age;
    mode = "400";
  };

  # Kimaki Discord bot credentials
  age.secrets.chassis_kimaki_env = {
    rekeyFile = ./files/kimaki/env.age;
    mode = "400";
  };

  home.stateVersion = "26.05";
}
