# ruinous.oi-cli.opencode.enable = true;
#
# Manages OpenCode CLI configuration with:
# - CLI binary installation (Linux only, use brew on macOS)
# - Main config (plugins, providers) synced via home-manager
# - oh-my-opencode agent configuration synced via home-manager
# - Automatic plugin installation via activation script
# - Local plugin support (e.g., opencode-notifier-apprise)
# - Multiple config directories with independent settings
#
# Example with multiple configs:
#   ruinous.ai-cli.opencode = {
#     enable = true;
#     plugins = [ "my-plugin" ];  # shared defaults
#
#     # oh-my-opencode agent model overrides
#     omoAgents = {
#       Sisyphus.model = "anthropic/claude-opus-4-5";
#       oracle.model = "openai/gpt-5.2";
#       explore.model = "opencode/grok-code";
#     };
#
#     configs = {
#       default = {};  # ~/.config/opencode with all defaults
#
#       web = {
#         configDir = "${config.home.homeDirectory}/.config/opencode-web";
#         notifier.enable = false;  # disable notifier for services
#       };
#
#       kimaki = {
#         configDir = "${config.home.homeDirectory}/.config/opencode-kimaki";
#         notifier.enable = false;
#       };
#     };
#   };
#
# See docs/ai-cli-sync-reference.md for details on what files are synced.
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ai-cli.opencode;
  opencode_config = flake + /files/configs/opencode/opencode.json;
  llmAgentsPkgs = flake.inputs.llm-agents.packages.${pkgs.system};

  # Permission submodule type for oh-my-opencode agents
  permissionType = types.submodule {
    options = {
      edit = mkOption {
        type = types.nullOr (types.enum ["ask" "allow" "deny"]);
        default = null;
        description = "Permission for file editing.";
      };
      bash = mkOption {
        type = types.nullOr (
          types.either
          (types.enum ["ask" "allow" "deny"])
          (types.attrsOf (types.enum ["ask" "allow" "deny"]))
        );
        default = null;
        description = "Permission for bash commands. Can be a string or an object mapping commands to permissions.";
      };
      webfetch = mkOption {
        type = types.nullOr (types.enum ["ask" "allow" "deny"]);
        default = null;
        description = "Permission for web fetching.";
      };
      doom_loop = mkOption {
        type = types.nullOr (types.enum ["ask" "allow" "deny"]);
        default = null;
        description = "Permission for doom loop detection.";
      };
      external_directory = mkOption {
        type = types.nullOr (types.enum ["ask" "allow" "deny"]);
        default = null;
        description = "Permission for external directory access.";
      };
    };
  };

  # oh-my-opencode agent submodule type
  omoAgentType = types.submodule {
    options = {
      model = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Model identifier for this agent (e.g., 'anthropic/claude-opus-4-5').";
        example = "anthropic/claude-opus-4-5";
      };
      category = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Category for this agent.";
      };
      skills = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "List of skills for this agent.";
      };
      temperature = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Temperature setting (0-2).";
      };
      top_p = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Top-p sampling setting (0-1).";
      };
      prompt = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom prompt for this agent.";
      };
      prompt_append = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Text to append to the agent's prompt.";
      };
      tools = mkOption {
        type = types.nullOr (types.attrsOf types.bool);
        default = null;
        description = "Tool enable/disable map.";
      };
      disable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether to disable this agent.";
      };
      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Description of this agent.";
      };
      mode = mkOption {
        type = types.nullOr (types.enum ["subagent" "primary" "all"]);
        default = null;
        description = "Agent mode.";
      };
      color = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Agent color in hex format (e.g., '#FF5733').";
      };
      permission = mkOption {
        type = types.nullOr permissionType;
        default = null;
        description = "Permission settings for this agent.";
      };
    };
  };

  # Helper to recursively remove null values from an attrset
  removeNulls = attrs:
    lib.filterAttrsRecursive (n: v: v != null) attrs;

  # JSON format helper for pretty-printed output
  jsonFormat = pkgs.formats.json {};

  # Generate oh-my-opencode.json content from config (pretty-printed)
  generateOmoConfig = agents: googleAuth:
    removeNulls {
      "$schema" = "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json";
      google_auth = googleAuth;
      agents =
        lib.mapAttrs (
          name: agentCfg:
            removeNulls {
              inherit (agentCfg) model category skills temperature top_p prompt prompt_append tools disable description mode color;
              permission =
                if agentCfg.permission != null
                then
                  removeNulls {
                    inherit (agentCfg.permission) edit bash webfetch doom_loop external_directory;
                  }
                else null;
            }
        )
        agents;
    };

  # MCP server submodule type (shared between main config and per-directory configs)
  mcpServerType = types.submodule ({name, ...}: {
    options = {
      type = mkOption {
        type = types.enum ["local" "remote"];
        description = "Type of the MCP server.";
      };
      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "URL for a remote MCP server.";
      };
      command = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Command to run a local MCP server.";
      };
      headers = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        default = null;
        description = lib.mdDoc ''
          HTTP headers for remote MCP servers. Useful for authentication.
          Use `{env:VAR_NAME}` syntax for environment variable references.
          Example: `{ "Authorization" = "Bearer {env:GITHUB_ACCESS_TOKEN}"; }`
        '';
      };
      env = mkOption {
        type = types.nullOr (types.attrsOf types.str);
        default = null;
        description = lib.mdDoc ''
          Environment variables for local MCP servers.
          Use `{env:VAR_NAME}` syntax for environment variable references.
          Example: `{ "MY_TOKEN" = "{env:MY_TOKEN}"; }`
        '';
      };
      oauth = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = lib.mdDoc ''
          Whether to use OAuth for authentication. Set to `false` when using
          Bearer token authentication via headers instead of OAuth flow.
        '';
      };
    };
  });

  # Config directory submodule type
  configDirType = types.submodule ({name, ...}: {
    options = {
      configDir = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Custom config directory path. If null, uses the default
          ~/.config/opencode (only valid for the "default" config).
        '';
        example = "/home/user/.config/opencode-web";
      };

      plugins = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = ''
          Override plugins for this config directory.
          If null, inherits from the main plugins setting.
        '';
      };

      mcpServers = mkOption {
        type = types.nullOr (types.attrsOf mcpServerType);
        default = null;
        description = ''
          Override MCP servers for this config directory.
          If null, inherits from the main mcpServers setting.
        '';
      };

      omoAgents = mkOption {
        type = types.nullOr (types.attrsOf omoAgentType);
        default = null;
        description = ''
          Override oh-my-opencode agents for this config directory.
          If null, inherits from the main omoAgents setting.
        '';
      };

      omoGoogleAuth = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Override oh-my-opencode Google auth setting for this config directory.
          If null, inherits from the main omoGoogleAuth setting.
        '';
      };

      codeyAgentSystemEnable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Override codey-agent-system AGENTS.md for this config directory.
          If null, inherits from the main codeyAgentSystem.enable setting.
        '';
      };

      notifier = {
        enable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = ''
            Override notifier setting for this config directory.
            If null, inherits from the main notifier.enable setting.
          '';
        };
      };

      installPlugins = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Override installPlugins setting for this config directory.
          If null, inherits from the main installPlugins setting.
        '';
      };
    };
  });

  # Resolve effective settings for a config directory
  resolveConfig = name: dirCfg: {
    configDir =
      if dirCfg.configDir != null
      then dirCfg.configDir
      else if name == "default"
      then "${config.xdg.configHome}/opencode"
      else throw "configDir must be specified for non-default config '${name}'";
    plugins =
      if dirCfg.plugins != null
      then dirCfg.plugins
      else cfg.plugins;
    mcpServers =
      if dirCfg.mcpServers != null
      then dirCfg.mcpServers
      else cfg.mcpServers;
    omoAgents =
      if dirCfg.omoAgents != null
      then dirCfg.omoAgents
      else cfg.omoAgents;
    omoGoogleAuth =
      if dirCfg.omoGoogleAuth != null
      then dirCfg.omoGoogleAuth
      else cfg.omoGoogleAuth;
    codeyAgentSystemEnable =
      if dirCfg.codeyAgentSystemEnable != null
      then dirCfg.codeyAgentSystemEnable
      else cfg.codeyAgentSystem.enable;
    notifierEnable =
      if dirCfg.notifier.enable != null
      then dirCfg.notifier.enable
      else cfg.notifier.enable;
    installPlugins =
      if dirCfg.installPlugins != null
      then dirCfg.installPlugins
      else cfg.installPlugins;
  };

  # Generate config files and activation scripts for a config directory
  mkConfigDir = name: dirCfg: let
    resolved = resolveConfig name dirCfg;
    safeName = builtins.replaceStrings ["-" "/"] ["_" "_"] name;
  in {
    # Activation script for this directory
    activation = lib.hm.dag.entryAfter ["writeBoundary"] ''
      CONFIG_DIR="${resolved.configDir}"
      CONFIG_FILE="$CONFIG_DIR/opencode.json"

      # Ensure config file exists, copy from template if not
      if [ ! -f "$CONFIG_FILE" ]; then
        $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"
        $DRY_RUN_CMD cp "${opencode_config}" "$CONFIG_FILE"
        $DRY_RUN_CMD chmod +w "$CONFIG_FILE"
      fi

      # Inject plugins into opencode.json if they are missing or need update
      if [ -f "$CONFIG_FILE" ]; then
        # Create a temporary file with the updated config
        TMP_FILE=$(mktemp)
        ${pkgs.jq}/bin/jq \
          --argjson new_plugins '${builtins.toJSON resolved.plugins}' \
          --argjson new_servers '${builtins.toJSON resolved.mcpServers}' \
          '
            # Ensure top-level keys exist
            .plugin //= []
            | .mcp = (.mcp // {}) + $new_servers
            # Reduce over new plugins to update or add them
            | reduce ($new_plugins[]) as $p (.;
                ( $p | split("@")[0] ) as $pname
                # Find index of existing plugin by name
                | (.plugin | map((. | split("@")[0]) == $pname) | index(true)) as $idx
                # If found, update it; otherwise, append it
                | if $idx != null then .plugin[$idx] = $p else .plugin += [$p] end
              )
            # Remove all null values from the final JSON
            | walk(if type == "object" then with_entries(select(.value != null)) else . end)
          ' "$CONFIG_FILE" > "$TMP_FILE"

        # If the file actually changed, update it
        if ! diff -q "$CONFIG_FILE" "$TMP_FILE" > /dev/null; then
          $DRY_RUN_CMD cp "$TMP_FILE" "$CONFIG_FILE"
          $DRY_RUN_CMD chmod +w "$CONFIG_FILE"
        fi
        rm "$TMP_FILE"
      fi

      ${optionalString resolved.installPlugins ''
        if command -v ${pkgs.bun}/bin/bun &> /dev/null; then
          $DRY_RUN_CMD ${pkgs.bun}/bin/bun install --cwd "$CONFIG_DIR" --silent 2>/dev/null || true
        fi
      ''}
    '';

    # Notifier activation for this directory
    notifierActivation = optionalString resolved.notifierEnable (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p "${resolved.configDir}/plugin"
        $DRY_RUN_CMD cp -f "${pkgs.opencode-notifier-apprise}/share/opencode-notifier-apprise/plugin.js" \
          "${resolved.configDir}/plugin/apprise-notifier.js"
      ''
    );

    inherit resolved;
  };

  # Process all config directories
  processedConfigs = mapAttrs mkConfigDir cfg.configs;

  # Check if any config has notifier enabled
  anyNotifierEnabled = any (c: c.resolved.notifierEnable) (attrValues processedConfigs);
in {
  options.ruinous.ai-cli.opencode = {
    enable = mkEnableOption "OpenCode CLI configuration management";

    installPlugins = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to automatically install plugins via bun on activation.";
    };

    plugins = mkOption {
      type = types.listOf types.str;
      default = [];
      example = lib.mdDoc ''
        # To add a plugin to the default list
        ruinous.ai-cli.opencode.plugins = [ "my-plugin" ];

        # To override the default list entirely
        ruinous.ai-cli.opencode.plugins = lib.mkForce [ "my-plugin" ];
      '';
      description = lib.mdDoc ''
        List of OpenCode plugins to install.
        By default, this list is appended to the internal default list of plugins.
        To completely override the default list, use `lib.mkForce`.
      '';
    };

    mcpServers = mkOption {
      type = types.attrsOf mcpServerType;
      default = {};
      example = lib.mdDoc ''
        # Add a remote server with Bearer token authentication
        ruinous.ai-cli.opencode.mcpServers.github = {
          type = "remote";
          url = "https://api.githubcopilot.com/mcp/";
          oauth = false;  # Required when using Bearer token instead of OAuth
          headers = {
            "Authorization" = "Bearer {env:GITHUB_ACCESS_TOKEN}";
          };
        };

        # Add a local server with environment variable in command
        ruinous.ai-cli.opencode.mcpServers.forgejo = {
          type = "local";
          command = [ "forgejo-mcp" "--transport" "stdio" "--url" "https://codeberg.org" "--token" "{env:FORGEJO_ACCESS_TOKEN}" ];
        };

        # Override all defaults
        ruinous.ai-cli.opencode.mcpServers = lib.mkForce { ... };
      '';
      description = lib.mdDoc ''
        Configuration for OpenCode MCP (Model Context Protocol) servers.
        This attrset is merged with the default servers.
        Use `lib.mkForce` to override all defaults.
      '';
    };

    omoAgents = mkOption {
      type = types.attrsOf omoAgentType;
      default = {};
      example = literalExpression ''
        {
          Sisyphus.model = "openai/gpt-5.2";
          oracle.model = "gpt-5.1-codex-max";
          librarian.model = "google/gemini-2.5-pro";
          explore.model = "xai/grok-code-fast-1";
          frontend-ui-ux-engineer = {
            model = "google/gemini-2.5-pro";
            temperature = 0.7;
          };
          document-writer.model = "google/gemini-2.5-flash";
          multimodal-looker.model = "google/gemini-2.5-flash-image";
        }
      '';
      # "Sisyphus": { "model": "openai/gpt-5.2" },
      # "oracle": { "model": "openai/gpt-5.1-codex-max" },
      # "librarian": { "model": "google/gemini-2.5-pro" },
      # "explore": { "model": "opencode/grok-code" },
      # "frontend-ui-ux-engineer": { "model": "google/gemini-2.5-pro" },
      # "document-writer": { "model": "google/gemini-2.5-flash" },
      # "multimodal-looker": { "model": "google/gemini-2.5-flash-image" }
      #   {
      #     Sisyphus.model = "anthropic/claude-opus-4-5";
      #     oracle.model = "openai/gpt-5.2";
      #     librarian.model = "anthropic/claude-sonnet-4-5";
      #     explore.model = "xai/grok-code-fast-1";
      #     frontend-ui-ux-engineer = {
      #       model = "google/gemini-2.5-pro";
      #       temperature = 0.7;
      #     };
      #   }
      # '';
      description = lib.mdDoc ''
        Configuration for oh-my-opencode agents.
        Each agent can have model, temperature, skills, and other settings.
        This attrset is merged with defaults. Use `lib.mkForce` to override all defaults.
      '';
    };

    omoGoogleAuth = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable Google authentication in oh-my-opencode.";
    };

    codeyAgentSystem = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable codey-agent-system (AGENTS.md, protocols, skills).";
      };
    };

    notifier = {
      enable = mkEnableOption "OpenCode Apprise notification plugin";
    };

    configs = mkOption {
      type = types.attrsOf configDirType;
      default = {
        default = {};
      };
      description = lib.mdDoc ''
        Multiple config directories with independent settings.
        Each entry creates a separate opencode config directory.
        The "default" entry uses ~/.config/opencode.
        Other entries must specify configDir explicitly.
        Settings can be overridden per-directory or inherited from the main config.
      '';
      example = literalExpression ''
        {
          default = {};  # ~/.config/opencode with all defaults

          web = {
            configDir = "''${config.home.homeDirectory}/.config/opencode-web";
            notifier.enable = false;
          };

          kimaki = {
            configDir = "''${config.home.homeDirectory}/.config/opencode-kimaki";
            notifier.enable = false;
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Base configuration and defaults
    {
      assertions =
        lib.mapAttrsToList (name: server: {
          assertion = (server.type == "remote" -> server.url != null) && (server.type == "local" -> server.command != null);
          message = "A remote MCP server must have a 'url' and a local server must have a 'command' for '${name}'.";
        })
        cfg.mcpServers;

      # Install opencode binary (Linux only - use brew on macOS)
      home.packages = mkIf pkgs.stdenv.isLinux [
        llmAgentsPkgs.opencode
      ];

      ruinous.ai-cli.opencode.plugins = [
        "oh-my-opencode@v3.0.0-beta.6"
        "opencode-openai-codex-auth@latest"
        "opencode-gemini-auth@latest"
        "opencode-anthropic-auth@0.0.8"
      ];

      # Default oh-my-opencode agent model configurations
      ruinous.ai-cli.opencode.omoAgents = {
        oracle.model = "openai/gpt-5.1-codex-max";
        librarian.model = "google/gemini-3-flash-preview";
        explore.model = "xai/grok-code-fast-1";
        frontend-ui-ux-engineer = {
          model = "google/gemini-2.5-pro";
          temperature = 0.7;
        };
        document-writer.model = "google/gemini-2.5-flash";
        multimodal-looker.model = "google/gemini-2.5-flash-image";
        # Sisyphus.model = "anthropic/claude-opus-4-5";
        # oracle.model = "openai/gpt-5.2";
        # librarian.model = "anthropic/claude-sonnet-4-5";
        # explore.model = "opencode/grok-code";
        # frontend-ui-ux-engineer.model = "google/gemini-2.5-pro";
        # document-writer.model = "google/gemini-2.5-flash";
        # multimodal-looker.model = "google/gemini-2.5-flash-image";
      };

      ruinous.ai-cli.opencode.mcpServers = {
        todoist = {
          type = "local";
          command = ["bunx" "-y" "mcp-remote" "https://ai.todoist.net/mcp"];
        };

        github = {
          type = "remote";
          url = "https://api.githubcopilot.com/mcp/";
          oauth = false;
          headers = {
            "Authorization" = "Bearer {env:GITHUB_ACCESS_TOKEN}";
          };
        };

        forgejo = {
          type = "local";
          command = ["${pkgs.forgejo-mcp}/bin/forgejo-mcp" "--transport" "stdio" "--url" "https://forge.meskill.farm" "--token" "{env:FORGEJO_ACCESS_TOKEN}"];
        };
      };
    }

    # Generate home.file entries for all config directories
    {
      home.file = mkMerge (map (name: let
        pc = processedConfigs.${name};
        resolved = pc.resolved;
      in
        {
          "${resolved.configDir}/oh-my-opencode.json".source =
            jsonFormat.generate "oh-my-opencode.json" (generateOmoConfig resolved.omoAgents resolved.omoGoogleAuth);
          "${resolved.configDir}/package.json".text = builtins.toJSON {
            name = "opencode-plugins";
            dependencies = builtins.listToAttrs (
              map (plugin: let
                parts = lib.splitString "@" plugin;
                pname = builtins.head parts;
                version =
                  if builtins.length parts > 1
                  then builtins.elemAt parts 1
                  else "latest";
              in {
                name = pname;
                value = version;
              })
              resolved.plugins
            );
          };
        }
        // optionalAttrs resolved.codeyAgentSystemEnable {
          "${resolved.configDir}/AGENTS.md".source = "${pkgs.codey-agent-system}/share/codey-agent-system/AGENTS.md";
          "${resolved.configDir}/protocols".source = "${pkgs.codey-agent-system}/share/codey-agent-system/protocols";
          "${resolved.configDir}/skill".source = "${pkgs.codey-agent-system}/share/codey-agent-system/skill";
        }) (attrNames cfg.configs));
    }

    # Generate activation scripts for all config directories
    {
      home.activation = mkMerge (map (name: let
        pc = processedConfigs.${name};
        safeName = builtins.replaceStrings ["-" "/" " "] ["_" "_" "_"] name;
      in
        {
          "opencode-plugins-${safeName}" = pc.activation;
        }
        // optionalAttrs pc.resolved.notifierEnable {
          "opencode-notifier-${safeName}" = pc.notifierActivation;
        }) (attrNames cfg.configs));
    }

    # Install notifier package if any config has it enabled
    (mkIf anyNotifierEnabled {
      home.packages = [pkgs.opencode-notifier-apprise];
    })
  ]);
}
