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
    flake.inputs.nix-openclaw.homeManagerModules.openclaw
  ];

  programs.wezterm.enable = true;

  # Allow git operations in budgey-assistant archive directory
  # The archive is owned by budgey-assistant service but extractors run as jmeskill
  programs.git.extraConfig.safe.directory = "/var/lib/budgey-assistant/archive";

  # GitHub and Forgejo CLI tools for openclaw issue management
  home.packages = with pkgs; [
    gh # GitHub CLI
    tea # Forgejo/Gitea CLI
    chat-organizer
  ];

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
            config.age.secrets.chassis_opencode_project_ruinagents_env.path
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

        # messy-attributes-editor - web service with Caddy
        messy-attributes-editor = {
          # Disable docs aggregation - upstream docs build needs fixing
          # (mkdocstrings can't find messy_attributes module in build env)
          docs.enable = false;
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

  age.secrets.chassis_opencode_project_ruinagents_env = {
    rekeyFile = ./files/opencode/projects/ruinagents.env.age;
    mode = "400";
  };

  # Openclaw - Personal AI Assistant for Discord
  # Minimal Discord-only configuration using Anthropic Claude
  # Secrets defined in hosts/chassis/openclaw.nix
  #
  # NOTE: nix-openclaw home-manager module has issues on NixOS:
  # 1. Uses hardcoded /bin/mkdir and /bin/ln (macOS paths)
  # 2. Systemd service doesn't properly handle secrets at runtime
  #
  # We disable the upstream module's systemd service and use a custom one.
  # The custom service reads secrets at runtime and sets environment variables.
  # Migration from fork (github:iamruinous/nix-moltbot) - see issue #391

  # Create required directories
  home.activation.clawdbotDirs = lib.mkForce (lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.clawdbot
    run ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.clawdbot/workspace
    run ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.clawdbot/workspace/memory
    run ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.clawdbot/agents/messy
    run ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.clawdbot/agents/messy/memory
    run ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.clawdbot/agents/codey
    run ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.clawdbot/agents/codey/memory
    run ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/.clawdbot/memory
    run ${pkgs.coreutils}/bin/mkdir -p /tmp/clawdbot
  '');

  # Disable upstream config file management
  home.activation.clawdbotConfigFiles = lib.mkForce (lib.hm.dag.entryAfter ["clawdbotDirs"] ''
    true
  '');

  # Generate valid openclaw config (token is read from env at runtime)
  # Use mkForce to override the upstream module's config file
  #
  # Key workarounds for nix-openclaw on NixOS:
  # 1. plugins.load.paths - bundled extensions aren't in default search path
  # 2. plugins.slots.memory = "memory-core" - explicit memory plugin
  # 3. plugins.entries.discord.enabled - explicitly enable discord plugin
  home.file.".clawdbot/clawdbot.json" = lib.mkForce {
    text = builtins.toJSON {
      gateway.mode = "local";
      plugins = {
        load.paths = [
          # Include bundled extensions from openclaw-gateway package
          # NOTE: This path may need updating when upstream package structure changes
          "${pkgs.openclaw-gateway}/lib/openclaw/node_modules/.pnpm/openclaw@2026.1.24-3_@types+express@5.0.6_audio-decode@2.2.3_devtools-protocol@0.0.1561482_typescript@5.9.3/node_modules/openclaw/extensions"
        ];
        slots.memory = "memory-core"; # Built-in memory using Markdown files + SQLite
        entries.discord.enabled = true; # Explicitly enable discord plugin
      };
      agents = {
        defaults = {
          workspace = "${config.home.homeDirectory}/.clawdbot/workspace";
          model.primary = "anthropic/claude-sonnet-4-20250514";
          thinkingDefault = "medium";
          # Enable semantic memory search with local embeddings (no API key needed)
          memorySearch = {
            enabled = true;
            provider = "local"; # Uses node-llama-cpp with local embedding model
          };
        };
        list = [
          {
            id = "main";
            default = true;
          }
          {
            id = "messy";
            workspace = "${config.home.homeDirectory}/.clawdbot/agents/messy";
          }
          {
            id = "codey";
            workspace = "${config.home.homeDirectory}/.clawdbot/agents/codey";
          }
        ];
      };
      channels = {
        discord = {
          enabled = true;
          # Allow bots to see webhook messages (required for #ops CTO triggers)
          # WARNING: Keep requireMention = true on most channels to prevent loops
          allowBots = true;
          # All Discord bots are defined as named accounts
          # Tokens are injected at runtime from agenix secrets
          accounts = {
            # Default account (main bot) - moltbot for general use
            default = {
              name = "Moltbot";
              enabled = true;
              token = "PLACEHOLDER_DEFAULT_TOKEN"; # Replaced at runtime
              dm = {
                enabled = true;
                policy = "open";
                allowFrom = ["*"];
              };
              groupPolicy = "allowlist";
              guilds = {
                "481143305745465354" = {
                  requireMention = true;
                  channels = {
                    # #moltbot-chat - no @ required (convention: *bot-chat channels)
                    "moltbot-chat" = {
                      requireMention = false;
                    };
                  };
                };
              };
            };
            # Messy account (separate bot for messy agent)
            messy = {
              name = "Messy Bot";
              enabled = true;
              token = "PLACEHOLDER_MESSY_TOKEN"; # Replaced at runtime
              dm = {
                enabled = true;
                policy = "open";
                allowFrom = ["*"];
              };
              groupPolicy = "allowlist";
              guilds = {
                "481143305745465354" = {
                  requireMention = true;
                  channels = {
                    # #messybot-chat - no @ required (convention: *bot-chat channels)
                    "messybot-chat" = {
                      requireMention = false;
                    };
                  };
                };
              };
            };
            # Codey account (separate bot for codey agent - #ops channel)
            codey = {
              name = "Codey Bot";
              enabled = true;
              token = "PLACEHOLDER_CODEY_TOKEN"; # Replaced at runtime
              dm = {
                enabled = true;
                policy = "open";
                allowFrom = ["*"];
              };
              groupPolicy = "allowlist";
              guilds = {
                "481143305745465354" = {
                  requireMention = true;
                  channels = {
                    # #codeybot-chat - no @ required (convention: *bot-chat channels)
                    "codeybot-chat" = {
                      requireMention = false;
                    };
                    # #ops - codey sees all messages (no @ required)
                    "ops" = {
                      requireMention = false;
                    };
                  };
                };
              };
            };
          };
        };
        whatsapp = {
          accounts.default = {
            enabled = true;
            dmPolicy = "allowlist";
            allowFrom = [];
          };
        };
      };
      # Session bridging: use main scope so all DMs share context per agent
      session = {
        dmScope = "main";
      };
      # Route channels to agents:
      # - Discord default → main agent
      # - Discord messy → messy agent (shares memory with WhatsApp!)
      # - Discord codey → codey agent (#ops channel)
      # - WhatsApp → messy agent
      bindings = [
        {
          agentId = "main";
          match = {
            channel = "discord";
            accountId = "default";
          };
        }
        {
          agentId = "messy";
          match = {
            channel = "discord";
            accountId = "messy";
          };
        }
        {
          agentId = "codey";
          match = {
            channel = "discord";
            accountId = "codey";
          };
        }
        {
          agentId = "messy";
          match = {channel = "whatsapp";};
        }
      ];
    };
  };

  # Custom systemd service that properly handles secrets
  # Restart trigger ensures service restarts when config changes
  systemd.user.services.clawdbot-gateway = {
    Unit = {
      Description = "Clawdbot gateway";
      # Restart when config file changes (home-manager will detect derivation changes)
      X-Restart-Triggers = ["${config.home.file.".clawdbot/clawdbot.json".source}"];
    };
    Service = {
      ExecStartPre = "${pkgs.writeShellScript "clawdbot-gateway-prepare" ''
        set -euo pipefail

        # Read WhatsApp allowFrom from agenix secret (one phone number per line, E.164 format)
        # Secret is optional - if not configured, WhatsApp will use empty allowlist
        WHATSAPP_ALLOWFROM_FILE="${
          if osConfig.age.secrets ? chassis_moltbot_whatsapp_allowfrom
          then osConfig.age.secrets.chassis_moltbot_whatsapp_allowfrom.path
          else ""
        }"
        if [ -n "$WHATSAPP_ALLOWFROM_FILE" ] && [ -f "$WHATSAPP_ALLOWFROM_FILE" ]; then
          # Convert newline-separated phone numbers to JSON array
          ALLOWFROM_JSON=$(${pkgs.jq}/bin/jq -R -s 'split("\n") | map(select(length > 0))' < "$WHATSAPP_ALLOWFROM_FILE")
        else
          ALLOWFROM_JSON='[]'
        fi

        # Read messy Discord bot token from agenix secret (optional)
        MESSY_DISCORD_TOKEN_FILE="${
          if osConfig.age.secrets ? chassis_moltbot_messy_discord_token
          then osConfig.age.secrets.chassis_moltbot_messy_discord_token.path
          else ""
        }"
        if [ -n "$MESSY_DISCORD_TOKEN_FILE" ] && [ -f "$MESSY_DISCORD_TOKEN_FILE" ]; then
          MESSY_DISCORD_TOKEN=$(cat "$MESSY_DISCORD_TOKEN_FILE")
        else
          MESSY_DISCORD_TOKEN=""
        fi

        # Read codey Discord bot token from agenix secret (optional)
        CODEY_DISCORD_TOKEN_FILE="${
          if osConfig.age.secrets ? chassis_moltbot_codey_discord_token
          then osConfig.age.secrets.chassis_moltbot_codey_discord_token.path
          else ""
        }"
        if [ -n "$CODEY_DISCORD_TOKEN_FILE" ] && [ -f "$CODEY_DISCORD_TOKEN_FILE" ]; then
          CODEY_DISCORD_TOKEN=$(cat "$CODEY_DISCORD_TOKEN_FILE")
        else
          CODEY_DISCORD_TOKEN=""
        fi

        # Read default Discord bot token from agenix secret
        DEFAULT_DISCORD_TOKEN=$(cat "${osConfig.age.secrets.chassis_moltbot_discord_token.path}")

        # Patch the config with secrets:
        # 1. WhatsApp allowFrom list
        # 2. Default Discord bot token (main bot)
        # 3. Messy Discord bot token (if configured)
        # 4. Codey Discord bot token (if configured)
        ${pkgs.jq}/bin/jq --argjson allowFrom "$ALLOWFROM_JSON" \
          --arg defaultToken "$DEFAULT_DISCORD_TOKEN" \
          --arg messyToken "$MESSY_DISCORD_TOKEN" \
          --arg codeyToken "$CODEY_DISCORD_TOKEN" \
          '.channels.whatsapp.accounts.default.allowFrom = $allowFrom |
           .channels.discord.accounts.default.token = $defaultToken |
           if $messyToken != "" then .channels.discord.accounts.messy.token = $messyToken else . end |
           if $codeyToken != "" then .channels.discord.accounts.codey.token = $codeyToken else . end' \
          "${config.home.homeDirectory}/.clawdbot/clawdbot.json" \
          > /tmp/clawdbot/clawdbot-runtime.json

        # Create openclaw-specific tea config with embedded token
        # This isolates openclaw's Forgejo auth from user's interactive config
        mkdir -p /tmp/clawdbot/config/tea
        FORGEJO_TOKEN=$(cat "${osConfig.age.secrets.chassis_moltbot_forgejo_token.path}")
        cat > /tmp/clawdbot/config/tea/config.yml << EOF
        logins:
          - name: forge.meskill.farm
            url: https://forge.meskill.farm
            token: $FORGEJO_TOKEN
            default: true
            user: iamruinous
        EOF
      ''}";
      ExecStart = "${pkgs.writeShellScript "clawdbot-gateway-start" ''
        set -euo pipefail

        # Read secrets from agenix-managed files
        export ANTHROPIC_API_KEY="$(cat ${osConfig.age.secrets.chassis_moltbot_anthropic_key.path})"
        export DISCORD_BOT_TOKEN="$(cat ${osConfig.age.secrets.chassis_moltbot_discord_token.path})"
        export CLAWDBOT_GATEWAY_TOKEN="$(cat ${osConfig.age.secrets.chassis_moltbot_gateway_token.path})"

        # GitHub CLI authentication (from Infisical via agenix-rekey)
        # gh CLI uses GITHUB_TOKEN or GH_TOKEN - no config file needed
        export GITHUB_TOKEN="$(cat ${osConfig.age.secrets.chassis_moltbot_github_token.path})"
        export GH_TOKEN="$GITHUB_TOKEN"

        # Tea/Forgejo CLI authentication
        # Use openclaw-specific config dir created in ExecStartPre
        # This isolates openclaw from user's interactive tea config
        export XDG_CONFIG_HOME="/tmp/clawdbot/config"
        # Also set env vars for direct API use and compatibility
        export GITEA_SERVER_URL="https://forge.meskill.farm"
        export GITEA_SERVER_TOKEN="$(cat ${osConfig.age.secrets.chassis_moltbot_forgejo_token.path})"
        export FORGEJO_TOKEN="$GITEA_SERVER_TOKEN"
        export GITEA_TOKEN="$GITEA_SERVER_TOKEN"

        # Add gh and tea CLI to PATH
        export PATH="${pkgs.gh}/bin:${pkgs.tea}/bin:$PATH"

        # Set openclaw environment - use runtime-patched config
        # NOTE: Environment variables still use CLAWDBOT_ prefix for backwards compat
        export HOME="${config.home.homeDirectory}"
        export CLAWDBOT_CONFIG_PATH="/tmp/clawdbot/clawdbot-runtime.json"
        export CLAWDBOT_STATE_DIR="${config.home.homeDirectory}/.clawdbot"
        export CLAWDBOT_NIX_MODE=1

        exec ${pkgs.openclaw}/bin/openclaw gateway --port 18789
      ''}";
      WorkingDirectory = "${config.home.homeDirectory}/.clawdbot";
      Restart = "always";
      RestartSec = "5s";
      StandardOutput = "append:/tmp/clawdbot/clawdbot-gateway.log";
      StandardError = "append:/tmp/clawdbot/clawdbot-gateway.log";
    };
    Install.WantedBy = ["default.target"];
  };

  # Create ~/.envrc with openclaw secrets for interactive use
  home.file.".envrc".text = ''
    # Openclaw secrets for interactive CLI use (tui, etc.)
    export CLAWDBOT_GATEWAY_TOKEN="$(cat ${osConfig.age.secrets.chassis_moltbot_gateway_token.path})"
    export ANTHROPIC_API_KEY="$(cat ${osConfig.age.secrets.chassis_moltbot_anthropic_key.path})"

    # GitHub/Forgejo CLI authentication (from Infisical via agenix-rekey)
    export GITHUB_TOKEN="$(cat ${osConfig.age.secrets.chassis_moltbot_github_token.path})"
    export GH_TOKEN="$GITHUB_TOKEN"
    export FORGEJO_TOKEN="$(cat ${osConfig.age.secrets.chassis_moltbot_forgejo_token.path})"
    export GITEA_TOKEN="$FORGEJO_TOKEN"
  '';

  # MESSY SOUL.md - Family assistant persona for WhatsApp
  # Derived from ruinagents persona definition (Boulder 3 Phase 1)
  # home.file.".clawdbot/agents/messy/SOUL.md".text = ''
  #   ---
  #   summary: "MESSY - Meskill Executive Support SYstem. Family assistant for the Meskill household."
  #   read_when:
  #     - "Every session start"
  #     - "When responding on WhatsApp"
  #   ---
  #
  #   # MESSY - Family Assistant
  #
  #   > "Keeping life running smoothly while the world goes off the rails."
  #
  #   ## Core Truths
  #
  #   - **You are the family assistant** for the Meskill household. Not a generic AI.
  #   - **Warm but efficient** — friendly without being overly chatty.
  #   - **Proactively helpful** — anticipate needs, flag concerns before they're asked.
  #   - **Context-aware** — distinguish between work, personal, and family contexts.
  #   - **Respectful of time** — key info first, scannable, concise. Use bullets.
  #   - **You know this family** — retrieve context, don't assume.
  #
  #   ## Decision Framework
  #
  #   When uncertain, ask: **"How will this make the family's day easier?"**
  #
  #   ## Communication Style
  #
  #   **Voice:** Like a trusted executive assistant who genuinely cares.
  #
  #   ### DO
  #
  #   - Warm greetings appropriate to time of day
  #   - Bullet points for lists and summaries
  #   - "Quick note:" or "Heads up:" for important callouts
  #   - Proactive suggestions ("Would you like me to...")
  #
  #   ### DON'T
  #
  #   - Robotic, cold language
  #   - Wall-of-text paragraphs
  #   - Excessive emoji
  #   - Generic assistant phrases ("As an AI assistant...")
  #   - "I'd be happy to help!" filler
  #
  #   ## Domain Boundaries
  #
  #   ### What I Handle
  #
  #   - Calendars (work, personal, family)
  #   - Tasks, reminders, follow-ups
  #   - Email triage and summaries
  #   - Travel coordination
  #   - Family events and scheduling
  #   - Household logistics
  #
  #   ### What I Don't Handle
  #
  #   - External news curation (NEWSY)
  #   - Technical documentation (LIBBY)
  #   - Coding tasks (sisyphus)
  #
  #   ## Escalation Rules
  #
  #   **Must Ask First:** Sharing private info, financial transactions >$100, canceling important appointments
  #
  #   **Proceed Then Inform:** Routine scheduling, reminders, calendar summaries
  #
  #   ## Platform Context
  #
  #   WhatsApp is home base. Keep messages scannable on mobile. Acknowledge receipt quickly.
  #
  #   ---
  #
  #   *MESSY v1.1.0 — Meskill Family Assistant*
  # '';

  # Openclaw tmuxp session for TUI access
  ruinous.tmuxp.sessions.openclaw = {
    startDirectory = "${config.home.homeDirectory}/.clawdbot";
    startCommands = ["source ${config.home.homeDirectory}/.envrc"];
    windows = [
      {
        name = "logs";
        command = "journalctl --user -u clawdbot-gateway -f";
      }
      {
        name = "tui";
        command = "openclaw tui";
        focus = true;
      }
      {
        name = "shell";
      }
    ];
  };

  # NOTE: We do NOT enable programs.openclaw because:
  # 1. The upstream schema-only config requires all options defined (no defaults)
  # 2. We use our own custom systemd service for proper secret handling
  # 3. We only need the overlay for pkgs.openclaw and pkgs.openclaw-gateway
  #
  # The overlay is added in hosts/chassis/openclaw.nix via:
  #   nixpkgs.overlays = [ flake.inputs.nix-openclaw.overlays.default ];
  #
  # Migration from fork (github:iamruinous/nix-moltbot) - see issue #391

  home.stateVersion = "26.05";
}
