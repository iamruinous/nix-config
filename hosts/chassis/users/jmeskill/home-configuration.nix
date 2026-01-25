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

      # Keep opencode-projects enabled for budgey-extractor registry
      # Projects are now managed via ruinous.ruinage.projects
      opencode-projects = {
        enable = true;
        environmentFiles = [
          config.age.secrets.chassis_opencode_common_env.path
        ];
        direnv.enable = true;
        defaultProject.enable = true;
        projects = {};
      };

      # Scheduled ingestion of OpenCode session data into PostgreSQL and Weaviate
      # Uses TCP with password auth via environment file
      budgey-extractor = {
        enable = true;
        environmentFile = config.age.secrets.chassis_budgey_env.path;
        weaviate.enable = true; # Uses WEAVIATE_URL and WEAVIATE_API_KEY from environmentFile
      };
    };

    ruinage = {
      # Kimaki Discord voice bot
      # Uses common.env for shared tokens (Git, CF, Todoist, Apprise)
      # Plus all project envs since it handles Discord requests for any project
      # Discord credentials stored in ~/.kimaki/discord-sessions.db
      assistants.kimaki = {
        enable = true;
        configDir = "${config.home.homeDirectory}/.config/kimaki";
        cacheDir = "${config.home.homeDirectory}/.cache/kimaki";
        stateDir = "${config.home.homeDirectory}/.local/state/kimaki";
        dataDir = "${config.home.homeDirectory}/.local/share/kimaki";
        environmentFiles = [
          config.age.secrets.chassis_opencode_common_env.path
          config.age.secrets.chassis_opencode_project_nix_env.path
          config.age.secrets.chassis_opencode_project_n8n_env.path
          config.age.secrets.chassis_opencode_project_budgey_extractor_env.path
          config.age.secrets.chassis_opencode_project_budgey_dashboard_env.path
        ];

        # Projects registered with kimaki for Discord channels
        # These map to the directories in ~/Projects/ruinous.ai/
        projects = {
          nix-config = {
            workdir = "${config.home.homeDirectory}/Projects/ruinous.ai/nix-config";
            direnvSnippet = "nix";
          };
          n8n-agent = {
            workdir = "${config.home.homeDirectory}/Projects/ruinous.ai/n8n-agent";
            direnvSnippet = "n8n";
          };
          dossiq-ai = {
            workdir = "${config.home.homeDirectory}/Projects/ruinous.ai/dossiq-ai";
            direnvSnippet = "dossiq";
          };
          ruinagents = {
            workdir = "${config.home.homeDirectory}/Projects/ruinous.ai/ruinagents";
            direnvSnippet = "ruinagents";
          };
          codey-agent-system = {
            workdir = "${config.home.homeDirectory}/Projects/ruinous.ai/codey-agent-system";
            # No direnv snippet - no project-specific env
          };
          ml-pspd = {
            workdir = "${config.home.homeDirectory}/Projects/ruinous.ai/ml-pspd";
            # No direnv snippet - no project-specific env
          };
        };
      };

      # Unified project-centric configuration
      # Projects with caddy.fqdn get:
      #   - Systemd user service (opencode web)
      #   - Caddy route (configured in chassis/caddy.nix)
      #   - CORS configured for the FQDN
      #   - tmuxp session in attach mode (no server window)
      #
      # Environment files:
      #   - common.env.age: Shared tokens (Git, CF, Todoist, Apprise)
      #   - projects/*.env.age: Per-project secrets (Postgres URIs, API keys)
      projects = {
        # nix-config - web service with Caddy
        nix = {
          repo = "nix-config";
          owner = "iamruinous";
          forge = "github.com";
          workdir = "${config.home.homeDirectory}/Projects/ruinage/nix-config";
          namespaces.ruinage.enable = true;
          assistants.opencode = {
            enable = true;
            port = 9500;
            caddy.fqdn = "nix.oc.ruinous.ai";
            web.enable = true;
          };
          tmuxp.enable = true;
          direnv.enable = true;
          budgey.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
            config.age.secrets.chassis_opencode_project_nix_env.path
          ];
        };

        # n8n-agent - web service with Caddy
        n8n = {
          repo = "n8n-agent";
          owner = "iamruinous";
          forge = "forge.meskill.farm";
          workdir = "${config.home.homeDirectory}/Projects/ruinage/n8n-agent";
          namespaces.ruinage.enable = true;
          assistants.opencode = {
            enable = true;
            port = 9501;
            caddy.fqdn = "n8n-agent.oc.ruinous.ai";
            web.enable = true;
          };
          tmuxp.enable = true;
          direnv.enable = true;
          budgey.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
            config.age.secrets.chassis_opencode_project_n8n_env.path
          ];
        };

        # dossiq-ai - web service with Caddy
        dossiq = {
          repo = "dossiq-ai";
          owner = "iamruinous";
          forge = "forge.meskill.farm";
          workdir = "${config.home.homeDirectory}/Projects/ruinage/dossiq-ai";
          namespaces.ruinage.enable = true;
          assistants.opencode = {
            enable = true;
            port = 9502;
            caddy.fqdn = "dossiq.oc.ruinous.ai";
            web.enable = true;
          };
          tmuxp = {
            enable = true;
            extraWindows = [
              {
                name = "tests";
                command = "uv run ptw";
              }
            ];
          };
          direnv.enable = true;
          budgey.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
          ];
        };

        # kimaki-discord-voice-bot - web service with Caddy
        kimaki-discord = {
          repo = "kimaki-discord-voice-bot";
          owner = "iamruinous";
          forge = "forge.meskill.farm";
          workdir = "${config.home.homeDirectory}/Projects/ruinage/kimaki-discord-voice-bot";
          namespaces.ruinage.enable = true;
          assistants.opencode = {
            enable = true;
            port = 9504;
            caddy.fqdn = "kimaki-discord.oc.ruinous.ai";
            web.enable = true;
          };
          tmuxp.enable = true;
          direnv.enable = true;
          budgey.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
          ];
        };

        # n8n-messy-discord-bot - web service with Caddy
        messy-discord = {
          repo = "n8n-messy-discord-bot";
          owner = "iamruinous";
          forge = "forge.meskill.farm";
          workdir = "${config.home.homeDirectory}/Projects/ruinage/n8n-messy-discord-bot";
          namespaces.ruinage.enable = true;
          assistants.opencode = {
            enable = true;
            port = 9505;
            caddy.fqdn = "messy-bot.oc.ruinous.ai";
            web.enable = true;
          };
          tmuxp.enable = true;
          direnv.enable = true;
          budgey.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
          ];
        };

        # ruinagents - web service with Caddy
        ruinagents = {
          repo = "ruinagents";
          owner = "iamruinous";
          forge = "forge.meskill.farm";
          workdir = "${config.home.homeDirectory}/Projects/ruinage/ruinagents";
          namespaces.ruinage.enable = true;
          assistants.opencode = {
            enable = true;
            port = 9507;
            caddy.fqdn = "ruinagents.oc.ruinous.ai";
            web.enable = true;
          };
          tmuxp.enable = true;
          direnv.enable = true;
          budgey.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
          ];
        };

        # budgey-extractor - web service with Caddy
        budgey-extractor = {
          repo = "budgey-extractor";
          owner = "iamruinous";
          forge = "forge.meskill.farm";
          workdir = "${config.home.homeDirectory}/Projects/ruinage/budgey-extractor";
          namespaces.ruinage.enable = true;
          assistants.opencode = {
            enable = true;
            port = 9508;
            caddy.fqdn = "budgey-extractor.oc.ruinous.ai";
            web.enable = true;
          };
          tmuxp.enable = true;
          direnv.enable = true;
          budgey.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
            config.age.secrets.chassis_opencode_project_budgey_extractor_env.path
          ];
        };

        # budgey-dashboard - web service with Caddy
        budgey-dashboard = {
          repo = "budgey-dashboard";
          owner = "iamruinous";
          forge = "forge.meskill.farm";
          workdir = "${config.home.homeDirectory}/Projects/ruinage/budgey-dashboard";
          namespaces.ruinage.enable = true;
          assistants.opencode = {
            enable = true;
            port = 9509;
            caddy.fqdn = "budgey-dashboard.oc.ruinous.ai";
            web.enable = true;
          };
          tmuxp.enable = true;
          direnv.enable = true;
          budgey.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
            config.age.secrets.chassis_opencode_project_budgey_dashboard_env.path
          ];
        };
      };
    };
  };

  # Common environment shared by all opencode-projects and kimaki
  age.secrets.chassis_opencode_common_env = {
    rekeyFile = ./files/opencode/common.env.age;
    mode = "400";
  };

  # Per-project environment files
  age.secrets.chassis_opencode_project_nix_env = {
    rekeyFile = ./files/opencode/projects/nix.env.age;
    mode = "400";
  };

  age.secrets.chassis_opencode_project_n8n_env = {
    rekeyFile = ./files/opencode/projects/n8n.env.age;
    mode = "400";
  };

  age.secrets.chassis_opencode_project_budgey_extractor_env = {
    rekeyFile = ./files/opencode/projects/budgey-extractor.env.age;
    mode = "400";
  };

  age.secrets.chassis_opencode_project_budgey_dashboard_env = {
    rekeyFile = ./files/opencode/projects/budgey-dashboard.env.age;
    mode = "400";
  };

  # Budgey-extractor service credentials (scheduled ingestion)
  age.secrets.chassis_budgey_env = {
    rekeyFile = ./files/budgey/env.age;
    mode = "400";
  };

  home.stateVersion = "26.05";
}
