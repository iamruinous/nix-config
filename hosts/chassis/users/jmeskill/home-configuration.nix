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

    ruinage = {
      enable = true;

      # Enable documentation aggregation site
      docs.enable = true;

      # Include default project for legacy interactive sessions
      budgey.defaultProject.opencode.enable = true;

      # Global OpenCode configuration
      assistants.opencode = {
        enable = true;
        # model, plugins, mcpServers, providers inherited from defaults
        harnesses.ruinagents.enable = true;
      };

      # Global Claude Code configuration
      assistants.claude-code = {
        enable = true;
        harnesses.ruinagents.enable = true;
      };

      # Global Gemini CLI configuration
      assistants.gemini = {
        enable = true;
        harnesses.ruinagents.enable = true;
      };

      # Global Codex CLI configuration
      assistants.codex = {
        enable = true;
        harnesses.ruinagents.enable = true;
      };

      # Kimaki Discord voice bot - global service configuration
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
        nix-config = {
          forge = "github.com"; # differs from default
          assistants.opencode = {
            enable = true;
            web.enable = true;
            budgey.enable = true;
          };
          assistants.kimaki.enable = true;
          direnv.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
            config.age.secrets.chassis_opencode_project_nix_env.path
          ];
        };

        # n8n-agent - web service with Caddy
        n8n-agent = {
          assistants.opencode = {
            enable = true;
            web.enable = true;
            budgey.enable = true;
          };
          assistants.kimaki.enable = true;
          direnv.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
            config.age.secrets.chassis_opencode_project_n8n_env.path
          ];
        };

        # dossiq-ai - web service with Caddy
        dossiq-ai = {
          assistants.opencode = {
            enable = true;
            web.enable = true;
            budgey.enable = true;
          };
          assistants.kimaki.enable = true;
          tmuxp.extraWindows = [
            {
              name = "tests";
              command = "uv run ptw";
            }
          ];
          direnv.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
          ];
        };

        # kimaki-discord-voice-bot - web service with Caddy
        kimaki-discord = {
          repo = "kimaki-discord-voice-bot"; # differs from project name
          assistants.opencode = {
            enable = true;
            web.enable = true;
            budgey.enable = true;
          };
          assistants.kimaki.enable = true;
          direnv.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
          ];
        };

        # n8n-messy-discord-bot - web service with Caddy
        messy-discord = {
          repo = "n8n-messy-discord-bot"; # differs from project name
          assistants.opencode = {
            enable = true;
            web.enable = true;
            budgey.enable = true;
          };
          assistants.kimaki.enable = true;
          direnv.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
          ];
        };

        # ruinagents - web service with Caddy
        ruinagents = {
          assistants.opencode = {
            enable = true;
            web.enable = true;
            budgey.enable = true;
          };
          assistants.kimaki.enable = true;
          direnv.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
          ];
        };

        # budgey-extractor - web service with Caddy
        budgey-extractor = {
          repo = "budgey-ingest-opencode";
          assistants.opencode = {
            enable = true;
            web.enable = true;
            budgey.enable = true;
          };
          assistants.kimaki.enable = true;
          direnv.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
            config.age.secrets.chassis_opencode_project_budgey_extractor_env.path
          ];
        };

        # budgey-dashboard - web service with Caddy
        budgey-dashboard = {
          assistants.opencode = {
            enable = true;
            web.enable = true;
            budgey.enable = true;
          };
          assistants.kimaki.enable = true;
          direnv.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
            config.age.secrets.chassis_opencode_project_budgey_dashboard_env.path
          ];
        };

        # budgey-assistant-ingest-tools - web service with Caddy
        budgey-assistant-ingest-tools = {
          assistants.opencode = {
            enable = true;
            web.enable = true;
            budgey.enable = true;
          };
          assistants.kimaki.enable = true;
          direnv.enable = true;
          environmentFiles = [
            config.age.secrets.chassis_opencode_common_env.path
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

  # Budgey-extractor scheduled ingestion - runs hourly
  # Uses incremental sync (only imports new sessions since last run)
  systemd.user.services.budgey-extractor = {
    Unit = {
      Description = "Budgey OpenCode Session Extractor";
      After = ["network-online.target"];
    };
    Service = {
      Type = "oneshot";
      EnvironmentFile = config.age.secrets.chassis_budgey_env.path;
      # Uses env vars: DATABASE_URL, WEAVIATE_URL, WEAVIATE_API_KEY
      ExecStart = let
        extractor = "${flake.inputs.budgey-extractor.packages.x86_64-linux.default}/bin/budgey-extractor";
      in "${extractor} ingest-postgres --dsn \${DATABASE_URL}";
      # TODO: Re-enable once issue #33 is fixed
      # ExecStartPost = let
      #   extractor = "${flake.inputs.budgey-extractor.packages.x86_64-linux.default}/bin/budgey-extractor";
      # in "${extractor} ingest-weaviate --weaviate-url \${WEAVIATE_URL} --weaviate-api-key \${WEAVIATE_API_KEY}";
    };
  };

  systemd.user.timers.budgey-extractor = {
    Unit = {
      Description = "Run Budgey Extractor hourly";
    };
    Timer = {
      OnCalendar = "hourly";
      Persistent = true; # Run immediately if missed (e.g., system was off)
      RandomizedDelaySec = "5m"; # Spread load
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };

  home.stateVersion = "26.05";
}
