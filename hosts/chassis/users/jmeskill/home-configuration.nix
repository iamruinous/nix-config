{
  flake,
  config,
  osConfig,
  pkgs,
  lib,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.kde
    flake.inputs.nix-moltbot.homeManagerModules.clawdbot
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

        # budgey-assistant-dashboard - web service with Caddy
        budgey-assistant-dashboard = {
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

  # Moltbot - Personal AI Assistant for Discord
  # Minimal Discord-only configuration using Anthropic Claude
  # Secrets defined in hosts/chassis/moltbot.nix
  #
  # NOTE: nix-moltbot home-manager module has multiple issues on NixOS:
  # 1. Uses hardcoded /bin/mkdir and /bin/ln (macOS paths)
  # 2. Generates invalid config keys (tokenFile, messages.queue.byProvider)
  # 3. Wrapper script doesn't properly interpolate secrets
  #
  # We disable the upstream module and use a custom systemd service instead.
  # The custom service reads secrets at runtime and sets environment variables.

  # Create required directories
  home.activation.clawdbotDirs = lib.mkForce (lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.clawdbot
    run ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.clawdbot/workspace
    run ${pkgs.coreutils}/bin/mkdir -p /tmp/clawdbot
  '');

  # Disable upstream config file management
  home.activation.clawdbotConfigFiles = lib.mkForce (lib.hm.dag.entryAfter ["clawdbotDirs"] ''
    true
  '');

  # Generate valid clawdbot config (token is read from env at runtime)
  # Use mkForce to override the upstream module's config file
  home.file.".clawdbot/clawdbot.json" = lib.mkForce {
    text = builtins.toJSON {
      gateway.mode = "local";
      agents = {
        defaults = {
          workspace = "${config.home.homeDirectory}/.clawdbot/workspace";
          model.primary = "anthropic/claude-sonnet-4-20250514";
          thinkingDefault = "medium";
        };
        list = [{ id = "main"; default = true; }];
      };
      channels.discord = {
        enabled = true;
        # Token is set via DISCORD_BOT_TOKEN env var at runtime
        dm = {
          policy = "pairing";
          allowFrom = [];
        };
      };
    };
  };

  # Custom systemd service that properly handles secrets
  systemd.user.services.clawdbot-gateway = {
    Unit.Description = "Clawdbot gateway";
    Service = {
      ExecStart = "${pkgs.writeShellScript "clawdbot-gateway-start" ''
        set -euo pipefail

        # Read secrets from agenix-managed files
        export ANTHROPIC_API_KEY="$(cat ${osConfig.age.secrets.chassis_moltbot_anthropic_key.path})"
        export DISCORD_BOT_TOKEN="$(cat ${osConfig.age.secrets.chassis_moltbot_discord_token.path})"

        # Set clawdbot environment
        export HOME="${config.home.homeDirectory}"
        export CLAWDBOT_CONFIG_PATH="${config.home.homeDirectory}/.clawdbot/clawdbot.json"
        export CLAWDBOT_STATE_DIR="${config.home.homeDirectory}/.clawdbot"
        export CLAWDBOT_NIX_MODE=1

        exec ${pkgs.clawdbot}/bin/clawdbot gateway --port 18789
      ''}";
      WorkingDirectory = "${config.home.homeDirectory}/.clawdbot";
      Restart = "always";
      RestartSec = "5s";
      StandardOutput = "append:/tmp/clawdbot/clawdbot-gateway.log";
      StandardError = "append:/tmp/clawdbot/clawdbot-gateway.log";
    };
    Install.WantedBy = ["default.target"];
  };

  # Keep upstream module enabled but disable its systemd service
  # We use our own custom service that properly handles secrets
  programs.clawdbot = {
    enable = true;

    # Disable upstream systemd service (we use our own)
    systemd.enable = false;

    # Default model configuration
    defaults = {
      model = "anthropic/claude-sonnet-4-20250514";
      thinkingDefault = "medium";
    };

    # Disable first-party plugins we don't need for minimal setup
    firstParty = {
      summarize.enable = false;
      peekaboo.enable = false;
      oracle.enable = false;
      poltergeist.enable = false;
      sag.enable = false;
      camsnap.enable = false;
      gogcli.enable = false;
      bird.enable = false;
      sonoscli.enable = false;
      imsg.enable = false;
    };

    # Keep default instance but disable its service
    instances.default = {
      enable = true;
      systemd.enable = false;
    };
  };

  home.stateVersion = "26.05";
}
