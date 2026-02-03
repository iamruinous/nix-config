{
  flake,
  config,
  osConfig,
  pkgs,
  lib,
  ...
}: let
  # Explicit package references from nix-openclaw flake input
  # (avoids deprecated nixpkgs.overlays with home-manager.useGlobalPkgs)
  openclawPkgs = flake.inputs.nix-openclaw.packages.${pkgs.system};
  # n0p package for Op management (isolated development sessions)
  n0pPkgs = flake.inputs.n0p.packages.${pkgs.system};
  # n0h package for host management CLI (login hub replacement)
  n0hPkgs = flake.inputs.n0h.packages.${pkgs.system};
in {
  imports = [
    flake.homeModules.default
    flake.homeModules.kde
    flake.inputs.nix-openclaw.homeManagerModules.openclaw
  ];

  programs.wezterm.enable = true;

  # Allow git operations in budgey-assistant archive directory
  # The archive is owned by budgey-assistant service but extractors run as jmeskill
  programs.git.settings.safe.directory = "/var/lib/budgey-assistant/archive";

  # GitHub and Forgejo CLI tools for openclaw issue management
  # n0p for isolated development sessions (worktrees + tmuxp)
  # n0h for host management and login hub
  home.packages = with pkgs; [
    gh # GitHub CLI
    tea # Forgejo/Gitea CLI
    chat-organizer
    n0pPkgs.n0p # Op management CLI
    n0pPkgs.worktrunk # Git worktree management (n0p dependency)
    n0hPkgs.n0h # Host management CLI (login hub)
  ];

  # n0h login hub - runs on SSH login instead of ruinous-login-hub
  programs.fish.interactiveShellInit = ''
    if test -z "$TMUX" -a -n "$SSH_TTY" -a -z "$BYPASS_LOGIN_HUB"
      exec ${n0hPkgs.n0h}/bin/n0h
    end
  '';

  ruinous = {
    rust-motd.enable = true;
    openssh.remote.forwarding.enable = true;
    loginHub.enable = false; # Replaced by n0h above

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
        harnesses.ruinagents.enable = true;

        # Override MCP servers to use file-based secrets from agenix
        # Uses lib.mkForce to replace default env-based configs
        # Secrets sourced from Infisical /shared path
        mcpServers = lib.mkForce {
          # GitHub Copilot MCP - uses shared GitHub token
          github = {
            type = "remote";
            url = "https://api.githubcopilot.com/mcp/";
            oauth = false;
            headers = {
              "Authorization" = "Bearer {file:${osConfig.age.secrets.chassis_opencode_github_token.path}}";
            };
          };

          # Forgejo MCP - for forge.meskill.farm
          forgejo = {
            type = "local";
            command = [
              "${pkgs.forgejo-mcp}/bin/forgejo-mcp"
              "--transport" "stdio"
              "--url" "https://forge.meskill.farm"
              "--token" "{file:${osConfig.age.secrets.chassis_opencode_forgejo_token.path}}"
            ];
          };

          # Todoist MCP - task management
          todoist = {
            type = "remote";
            url = "https://ai.todoist.net/mcp";
            headers = {
              "Authorization" = "Bearer {file:${osConfig.age.secrets.chassis_opencode_todoist_token.path}}";
            };
          };

          # Context7 MCP - library documentation lookup
          context7 = {
            type = "remote";
            url = "https://mcp.context7.com/mcp";
            headers = {
              "Authorization" = "Bearer {file:${osConfig.age.secrets.chassis_opencode_context7_key.path}}";
            };
          };
        };
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

  # Openclaw - Personal AI Assistant for Discord and WhatsApp
  # Uses upstream nix-openclaw module with custom systemd service for secret injection
  # Secrets defined in hosts/chassis/openclaw.nix
  #
  # Configuration approach (similar to opencode):
  # 1. Base config written as template via home.activation (writable, not symlinked)
  # 2. ExecStartPre injects secrets from agenix at service start
  # 3. Runtime changes preserved (user can modify config)
  programs.openclaw = {
    enable = true;
    # Explicit package reference (overlay removed due to useGlobalPkgs deprecation)
    package = openclawPkgs.openclaw;
    # Disable upstream systemd - we provide our own with secret injection
    systemd.enable = false;
    # State directory (migrated from .clawdbot)
    stateDir = "${config.home.homeDirectory}/.openclaw";
    workspaceDir = "${config.home.homeDirectory}/.openclaw/workspace";
  };

  # Override upstream module's config file - we manage it ourselves via activation
  # Disable both the home.file entry AND the activation that creates a symlink
  home.file.".openclaw/openclaw.json".enable = lib.mkForce false;
  home.activation.openclawConfigFiles = lib.mkForce (lib.hm.dag.entryAfter ["writeBoundary"] "");

  # Base openclaw config - written as writable file via activation
  # Secrets (tokens) are injected at service start via ExecStartPre
  home.activation.openclawConfig = let
    openclawStateDir = "${config.home.homeDirectory}/.openclaw";
    baseConfig = builtins.toJSON {
      gateway.mode = "local";
      plugins = {
        load.paths = [
          # Include bundled extensions from openclaw-gateway package
          "${openclawPkgs.openclaw-gateway}/lib/openclaw/extensions"
        ];
        slots.memory = "memory-core"; # Built-in memory using Markdown files + SQLite
        entries.discord.enabled = true; # Explicitly enable discord plugin
      };
      agents = {
        defaults = {
          workspace = "${openclawStateDir}/workspace";
          # OpenAI primary with Claude fallback
          model = {
            primary = "openai/gpt-5.2";
            fallbacks = ["anthropic/claude-sonnet-4-5"];
          };
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
            workspace = "${openclawStateDir}/agents/messy";
          }
          {
            id = "codey";
            workspace = "${openclawStateDir}/agents/codey";
            # Mention patterns allow triggering without @mention
            # These work even when requireMention = true
            groupChat = {
              mentionPatterns = [
                "CODEY:"
                "CTO:"
                "@codey"
                "hey codey"
                "codey,"
              ];
            };
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
            # Default account (main bot) - openclaw for general use
            default = {
              name = "Openclaw";
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
                    # #openclaw-chat - no @ required (convention: *bot-chat channels)
                    "openclaw-chat" = {
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
            # NOTE: Codey responds to mentionPatterns (CODEY:, CTO:, etc.) without @mention
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
                    # #ops - inherits requireMention = true from guild default
                    # Codey still responds to mentionPatterns (CODEY:, CTO:, etc.)
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
    baseConfigFile = pkgs.writeText "openclaw-base.json" baseConfig;
  in
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      CONFIG_DIR="${openclawStateDir}"
      CONFIG_FILE="$CONFIG_DIR/openclaw.json"

      $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"
      $DRY_RUN_CMD mkdir -p "$CONFIG_DIR/workspace"
      $DRY_RUN_CMD mkdir -p "$CONFIG_DIR/agents/messy"
      $DRY_RUN_CMD mkdir -p "$CONFIG_DIR/agents/codey"
      # Create templates directory (workaround for missing templates in nix package)
      # The gateway looks for docs/reference/templates/ in cwd before falling back to package
      $DRY_RUN_CMD mkdir -p "$CONFIG_DIR/docs/reference/templates"

      # Remove symlink if it exists (upstream module creates one, we want writable file)
      if [ -L "$CONFIG_FILE" ]; then
        $DRY_RUN_CMD rm "$CONFIG_FILE"
      fi

      # Create config file if it doesn't exist (writable, not symlinked)
      if [ ! -f "$CONFIG_FILE" ]; then
        $DRY_RUN_CMD cp "${baseConfigFile}" "$CONFIG_FILE"
        $DRY_RUN_CMD chmod 600 "$CONFIG_FILE"
      else
        # Merge managed settings into existing config (preserve user changes)
        # Update plugins.load.paths and agents.defaults.workspace
        TMP_FILE=$(mktemp)
        ${pkgs.jq}/bin/jq \
          --argjson base_plugins '${builtins.toJSON {
        load.paths = ["${openclawPkgs.openclaw-gateway}/lib/openclaw/extensions"];
        slots.memory = "memory-core";
        entries.discord.enabled = true;
      }}' \
          --arg workspace "${openclawStateDir}/workspace" \
          '.plugins = $base_plugins | .agents.defaults.workspace = $workspace' \
          "$CONFIG_FILE" > "$TMP_FILE"

        if ! diff -q "$CONFIG_FILE" "$TMP_FILE" > /dev/null 2>&1; then
          $DRY_RUN_CMD install -m 600 "$TMP_FILE" "$CONFIG_FILE"
        fi
        rm -f "$TMP_FILE"
      fi

      # Copy templates from workspace if they exist (workaround for nix package bug)
      TEMPLATE_DIR="$CONFIG_DIR/docs/reference/templates"
      for template in AGENTS.md SOUL.md TOOLS.md BOOTSTRAP.md HEARTBEAT.md IDENTITY.md USER.md; do
        if [ -f "$CONFIG_DIR/workspace/$template" ] && [ ! -f "$TEMPLATE_DIR/$template" ]; then
          $DRY_RUN_CMD cp "$CONFIG_DIR/workspace/$template" "$TEMPLATE_DIR/$template"
        fi
      done
    '';

  # Systemd service with secret injection via ExecStartPre
  systemd.user.services.openclaw-gateway = {
    Unit = {
      Description = "Openclaw gateway";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };
    Service = {
      ExecStartPre = "${pkgs.writeShellScript "openclaw-gateway-prepare" ''
                set -euo pipefail

                # Create runtime directories
                mkdir -p /tmp/openclaw

                # Read WhatsApp allowFrom from agenix secret (one phone number per line, E.164 format)
                # Secret is optional - if not configured, WhatsApp will use empty allowlist
                WHATSAPP_ALLOWFROM_FILE="${
          if osConfig.age.secrets ? chassis_openclaw_whatsapp_allowfrom
          then osConfig.age.secrets.chassis_openclaw_whatsapp_allowfrom.path
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
          if osConfig.age.secrets ? chassis_openclaw_messy_discord_token
          then osConfig.age.secrets.chassis_openclaw_messy_discord_token.path
          else ""
        }"
                if [ -n "$MESSY_DISCORD_TOKEN_FILE" ] && [ -f "$MESSY_DISCORD_TOKEN_FILE" ]; then
                  MESSY_DISCORD_TOKEN=$(cat "$MESSY_DISCORD_TOKEN_FILE")
                else
                  MESSY_DISCORD_TOKEN=""
                fi

                # Read codey Discord bot token from agenix secret (optional)
                CODEY_DISCORD_TOKEN_FILE="${
          if osConfig.age.secrets ? chassis_openclaw_codey_discord_token
          then osConfig.age.secrets.chassis_openclaw_codey_discord_token.path
          else ""
        }"
                if [ -n "$CODEY_DISCORD_TOKEN_FILE" ] && [ -f "$CODEY_DISCORD_TOKEN_FILE" ]; then
                  CODEY_DISCORD_TOKEN=$(cat "$CODEY_DISCORD_TOKEN_FILE")
                else
                  CODEY_DISCORD_TOKEN=""
                fi

                # Read default Discord bot token from agenix secret
                DEFAULT_DISCORD_TOKEN=$(cat "${osConfig.age.secrets.chassis_openclaw_discord_token.path}")

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
                  "${config.home.homeDirectory}/.openclaw/openclaw.json" \
                  > /tmp/openclaw/openclaw-runtime.json

                # Create openclaw-specific tea config with embedded token
                # This isolates openclaw's Forgejo auth from user's interactive config
                mkdir -p /tmp/openclaw/config/tea
                FORGEJO_TOKEN=$(cat "${osConfig.age.secrets.chassis_openclaw_forgejo_token.path}")
                cat > /tmp/openclaw/config/tea/config.yml << EOF
        logins:
          - name: forge.meskill.farm
            url: https://forge.meskill.farm
            token: $FORGEJO_TOKEN
            default: true
            user: iamruinous
        EOF
      ''}";
      ExecStart = "${pkgs.writeShellScript "openclaw-gateway-start" ''
        set -euo pipefail

        # Read secrets from agenix-managed files
        export ANTHROPIC_API_KEY="$(cat ${osConfig.age.secrets.chassis_openclaw_anthropic_key.path})"
        export OPENAI_API_KEY="$(cat ${osConfig.age.secrets.chassis_openclaw_openai_key.path})"
        export DISCORD_BOT_TOKEN="$(cat ${osConfig.age.secrets.chassis_openclaw_discord_token.path})"
        export OPENCLAW_GATEWAY_TOKEN="$(cat ${osConfig.age.secrets.chassis_openclaw_gateway_token.path})"

        # GitHub CLI authentication (from Infisical via agenix-rekey)
        # gh CLI uses GITHUB_TOKEN or GH_TOKEN - no config file needed
        export GITHUB_TOKEN="$(cat ${osConfig.age.secrets.chassis_openclaw_github_token.path})"
        export GH_TOKEN="$GITHUB_TOKEN"

        # Tea/Forgejo CLI authentication
        # Use openclaw-specific config dir created in ExecStartPre
        # This isolates openclaw from user's interactive tea config
        export XDG_CONFIG_HOME="/tmp/openclaw/config"
        # Also set env vars for direct API use and compatibility
        export GITEA_SERVER_URL="https://forge.meskill.farm"
        export GITEA_SERVER_TOKEN="$(cat ${osConfig.age.secrets.chassis_openclaw_forgejo_token.path})"
        export FORGEJO_TOKEN="$GITEA_SERVER_TOKEN"
        export GITEA_TOKEN="$GITEA_SERVER_TOKEN"

        # Add gh and tea CLI to PATH
        export PATH="${pkgs.gh}/bin:${pkgs.tea}/bin:$PATH"

        # Set openclaw environment - use runtime-patched config
        export HOME="${config.home.homeDirectory}"
        export OPENCLAW_CONFIG_PATH="/tmp/openclaw/openclaw-runtime.json"
        export OPENCLAW_STATE_DIR="${config.home.homeDirectory}/.openclaw"
        export OPENCLAW_NIX_MODE=1

        exec ${openclawPkgs.openclaw}/bin/openclaw gateway --port 18789
      ''}";
      WorkingDirectory = "${config.home.homeDirectory}/.openclaw";
      Restart = "always";
      RestartSec = "5s";
      StandardOutput = "append:/tmp/openclaw/openclaw-gateway.log";
      StandardError = "append:/tmp/openclaw/openclaw-gateway.log";
    };
    Install.WantedBy = ["default.target"];
  };

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
  # Secrets are loaded inline from agenix paths (no ~/.envrc needed)
  ruinous.tmuxp.sessions.openclaw = {
    startDirectory = "${config.home.homeDirectory}/.openclaw";
    startCommands = [
      "export OPENCLAW_GATEWAY_TOKEN=\"$(cat ${osConfig.age.secrets.chassis_openclaw_gateway_token.path})\""
      "export ANTHROPIC_API_KEY=\"$(cat ${osConfig.age.secrets.chassis_openclaw_anthropic_key.path})\""
    ];
    windows = [
      {
        name = "logs";
        command = "journalctl --user -u openclaw-gateway -f";
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

  home.stateVersion = "26.05";
}
