# ruinous.oi-cli.opencode.enable = true;
#
# Manages OpenCode CLI configuration with:
# - CLI binary installation (Linux only, use brew on macOS)
# - Default model configuration (primary model for OpenCode)
# - Main config (plugins, providers) synced via home-manager
# - oh-my-opencode agent and category configuration synced via home-manager
# - Automatic plugin installation via activation script
# - Local plugin support (e.g., opencode-notifier-apprise)
# - Multiple config directories with independent settings
#
# Example with model and category overrides:
#   ruinous.ai-cli.opencode = {
#     enable = true;
#     model = "anthropic/claude-opus-4-5";  # default model for OpenCode
#     plugins = [ "my-plugin" ];  # shared defaults
#
#     # oh-my-opencode agent model overrides (optional, for subagents)
#     omoAgents = {
#       oracle.model = "openai/gpt-5.2";
#       librarian.model = "google/gemini-3-flash-preview";
#       explore.model = "xai/grok-code-fast-1";
#     };
#
#     # oh-my-opencode category configuration (optional)
#     omoCategories = {
#       # Custom category
#       korean-writer = {
#         model = "google/gemini-3-flash-preview";
#         temperature = 0.5;
#         prompt_append = "You are a Korean technical writer.";
#       };
#       # Override built-in category
#       visual-engineering.model = "openai/gpt-5.2";
#       # Configure thinking model
#       deep-reasoning = {
#         model = "anthropic/claude-opus-4-5";
#         thinking = { type = "enabled"; budgetTokens = 32000; };
#       };
#     };
#
#     # Disable specific skills
#     disabledSkills = [ "playwright" ];
#
#     configs = {
#       default = {};  # ~/.config/opencode with all defaults
#
#       web = {
#         configDir = "${config.home.homeDirectory}/.config/opencode-web";
#         model = "anthropic/claude-sonnet-4";  # different model for web config
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

  # Thinking configuration submodule type for categories
  thinkingType = types.submodule {
    options = {
      type = mkOption {
        type = types.nullOr (types.enum ["enabled" "disabled"]);
        default = null;
        description = "Whether thinking mode is enabled or disabled.";
      };
      budgetTokens = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Token budget for thinking mode.";
        example = 32000;
      };
    };
  };

  # oh-my-opencode category submodule type
  omoCategoryType = types.submodule {
    options = {
      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Human-readable description of the category's purpose.";
      };
      model = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "AI model ID to use (e.g., 'anthropic/claude-opus-4-5').";
        example = "anthropic/claude-opus-4-5";
      };
      variant = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Model variant (e.g., 'max', 'xhigh').";
        example = "max";
      };
      temperature = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Creativity level (0.0 ~ 2.0). Lower is more deterministic.";
      };
      top_p = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "Nucleus sampling parameter (0.0 ~ 1.0).";
      };
      prompt_append = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Content to append to system prompt when this category is selected.";
      };
      thinking = mkOption {
        type = types.nullOr thinkingType;
        default = null;
        description = "Thinking model configuration.";
        example = {
          type = "enabled";
          budgetTokens = 16000;
        };
      };
      reasoningEffort = mkOption {
        type = types.nullOr (types.enum ["low" "medium" "high"]);
        default = null;
        description = "Reasoning effort level.";
      };
      textVerbosity = mkOption {
        type = types.nullOr (types.enum ["low" "medium" "high"]);
        default = null;
        description = "Text verbosity level.";
      };
      tools = mkOption {
        type = types.nullOr (types.attrsOf types.bool);
        default = null;
        description = "Tool usage control (disable with { \"tool_name\" = false; }).";
      };
      maxTokens = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum response token count.";
      };
      is_unstable_agent = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Mark agent as unstable - forces background mode for monitoring.";
      };
    };
  };

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
  generateOmoConfig = {
    agents,
    categories,
    disabledSkills,
    googleAuth,
  }:
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
      categories =
        lib.mapAttrs (
          name: catCfg:
            removeNulls {
              inherit (catCfg) description model variant temperature top_p prompt_append reasoningEffort textVerbosity tools maxTokens is_unstable_agent;
              thinking =
                if catCfg.thinking != null
                then
                  removeNulls {
                    inherit (catCfg.thinking) type budgetTokens;
                  }
                else null;
            }
        )
        categories;
      disabled_skills = disabledSkills;
    };

  # Provider model submodule type
  providerModelType = types.submodule {
    options = {
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Display name for the model.";
        example = "Qwen 2.5 Coder 7B";
      };
      maxTokens = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum token limit for the model.";
        example = 16384;
      };
    };
  };

  # Provider options submodule type (nested under provider.options)
  providerOptionsType = types.submodule {
    options = {
      baseURL = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc ''
          Base URL for the provider API.
          Use `{env:VAR_NAME}` syntax for environment variable references.
        '';
        example = "https://zenith.cpp.ruinous.ai/v1";
      };
      apiKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc ''
          API key for authentication. For self-hosted servers without auth,
          use a dummy value like "not-needed".
          Use `{env:VAR_NAME}` syntax for environment variable references.
        '';
        example = "not-needed";
      };
    };
  };

  # Provider submodule type for custom LLM providers (vLLM, Ollama, etc.)
  providerType = types.submodule ({name, ...}: {
    options = {
      api = mkOption {
        type = types.enum ["openai" "anthropic" "google" "ollama"];
        default = "openai";
        description = lib.mdDoc ''
          API type for the provider. Most self-hosted LLM servers (vLLM, llama.cpp)
          use "openai" since they expose an OpenAI-compatible API.
        '';
        example = "openai";
      };
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Display name for the provider.";
        example = "Zenith vLLM";
      };
      options = mkOption {
        type = types.nullOr providerOptionsType;
        default = null;
        description = lib.mdDoc ''
          Provider options including baseURL and apiKey.
          Use `{env:VAR_NAME}` syntax for environment variable references.
        '';
        example = literalExpression ''
          {
            baseURL = "https://zenith.cpp.ruinous.ai/v1";
            apiKey = "not-needed";
          }
        '';
      };
      models = mkOption {
        type = types.attrsOf providerModelType;
        default = {};
        description = lib.mdDoc ''
          Models available from this provider.
          Keys are model identifiers (e.g., "Qwen/Qwen2.5-Coder-7B-Instruct"),
          values contain display name and optional maxTokens.
        '';
        example = literalExpression ''
          {
            "Qwen/Qwen2.5-Coder-7B-Instruct" = {
              name = "Qwen 2.5 Coder 7B";
              maxTokens = 16384;
            };
          }
        '';
      };
    };
  });

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

      model = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Override the default model for this config directory.
          If null, inherits from the main model setting.
        '';
        example = "anthropic/claude-opus-4-5";
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

      omoCategories = mkOption {
        type = types.nullOr (types.attrsOf omoCategoryType);
        default = null;
        description = ''
          Override oh-my-opencode categories for this config directory.
          If null, inherits from the main omoCategories setting.
        '';
      };

      disabledSkills = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = ''
          Override disabled skills for this config directory.
          If null, inherits from the main disabledSkills setting.
        '';
      };

      providers = mkOption {
        type = types.nullOr (types.attrsOf providerType);
        default = null;
        description = ''
          Override providers for this config directory.
          If null, inherits from the main providers setting.
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

      ruinagentsGlobalEnable = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Override ruinagents-global AGENTS.md for this config directory.
          If null, inherits from the main ruinagentsGlobal.enable setting.
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
    model =
      if dirCfg.model != null
      then dirCfg.model
      else cfg.model;
    plugins =
      if dirCfg.plugins != null
      then dirCfg.plugins
      else cfg.plugins;
    mcpServers =
      if dirCfg.mcpServers != null
      then dirCfg.mcpServers
      else cfg.mcpServers;
    providers =
      if dirCfg.providers != null
      then dirCfg.providers
      else cfg.providers;
    omoAgents =
      if dirCfg.omoAgents != null
      then dirCfg.omoAgents
      else cfg.omoAgents;
    omoCategories =
      if dirCfg.omoCategories != null
      then dirCfg.omoCategories
      else cfg.omoCategories;
    disabledSkills =
      if dirCfg.disabledSkills != null
      then dirCfg.disabledSkills
      else cfg.disabledSkills;
    omoGoogleAuth =
      if dirCfg.omoGoogleAuth != null
      then dirCfg.omoGoogleAuth
      else cfg.omoGoogleAuth;
    ruinagentsGlobalEnable =
      if dirCfg.ruinagentsGlobalEnable != null
      then dirCfg.ruinagentsGlobalEnable
      else cfg.ruinagentsGlobal.enable;
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

      # Inject model, plugins, MCP servers, and providers into opencode.json
      # Provider replacement: completely replaces managed entries to apply schema changes
      if [ -f "$CONFIG_FILE" ]; then
        # Create a temporary file with the updated config
        TMP_FILE=$(mktemp)
        ${pkgs.jq}/bin/jq \
          --argjson new_model '${builtins.toJSON resolved.model}' \
          --argjson new_plugins '${builtins.toJSON resolved.plugins}' \
          --argjson new_servers '${builtins.toJSON resolved.mcpServers}' \
          --argjson new_providers '${builtins.toJSON resolved.providers}' \
          '(if $new_model != null then .model = $new_model else . end)
            | .plugin //= []
            | .mcp = (.mcp // {}) + $new_servers
            | .provider = (((.provider // {}) | to_entries | map(select(.key as $k | $new_providers | has($k) | not)) | from_entries) + $new_providers)
            | reduce ($new_plugins[]) as $p (.;
                ($p | split("@")[0]) as $pname
                | ((.plugin | map((. | split("@")[0]) == $pname) | index(true))) as $idx
                | if $idx != null then .plugin[$idx] = $p else .plugin += [$p] end)
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

  ruinagentsGlobalPackage = pkgs.ruinagents-global;
  ruinagentsGlobalShare = "${ruinagentsGlobalPackage}/share/ruinagents-global";
  firstExisting = paths: let
    existing = builtins.filter (path: builtins.pathExists path) paths;
  in
    if existing == []
    then null
    else builtins.head existing;
  skillSourcePath = firstExisting [
    "${ruinagentsGlobalShare}/skill"
    "${ruinagentsGlobalShare}/.skills"
  ];
  commandSourcePath = firstExisting [
    "${ruinagentsGlobalShare}/command"
    "${ruinagentsGlobalShare}/commands"
    "${ruinagentsGlobalShare}/.command"
    "${ruinagentsGlobalShare}/.commands"
  ];
  skillNames =
    if skillSourcePath == null
    then []
    else builtins.filter (name: builtins.pathExists "${skillSourcePath}/${name}/SKILL.md") (builtins.attrNames (builtins.readDir skillSourcePath));
  commandNames =
    if commandSourcePath == null
    then []
    else builtins.filter (name: builtins.pathExists "${commandSourcePath}/${name}") (builtins.attrNames (builtins.readDir commandSourcePath));
in {
  options.ruinous.ai-cli.opencode = {
    enable = mkEnableOption "OpenCode CLI configuration management";

    model = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "anthropic/claude-opus-4-5";
      description = lib.mdDoc ''
        Default model for OpenCode. This sets the `model` field in `opencode.json`.
        When set, this is the primary model OpenCode uses for all interactions.
        If null, no model is set and OpenCode will use its built-in default.

        Example values:
        - `"anthropic/claude-opus-4-5"` - Claude Opus 4.5
        - `"anthropic/claude-sonnet-4"` - Claude Sonnet 4
        - `"openai/gpt-5.2"` - GPT 5.2
        - `"google/gemini-2.5-pro"` - Gemini 2.5 Pro
      '';
    };

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
      description = lib.mdDoc ''
        Configuration for oh-my-opencode agents.
        Each agent can have model, temperature, skills, and other settings.
        This attrset is merged with defaults. Use `lib.mkForce` to override all defaults.
      '';
    };

    omoCategories = mkOption {
      type = types.attrsOf omoCategoryType;
      default = {};
      example = literalExpression ''
        {
          # Define new custom category
          korean-writer = {
            model = "google/gemini-3-flash-preview";
            temperature = 0.5;
            prompt_append = "You are a Korean technical writer. Maintain a friendly and clear tone.";
          };

          # Override existing category
          visual-engineering = {
            model = "openai/gpt-5.2";
            temperature = 0.8;
          };

          # Configure thinking model
          deep-reasoning = {
            model = "anthropic/claude-opus-4-5";
            thinking = {
              type = "enabled";
              budgetTokens = 32000;
            };
            tools = {
              websearch_web_search_exa = false;
            };
          };
        }
      '';
      description = lib.mdDoc ''
        Configuration for oh-my-opencode categories.
        Categories are agent configuration presets optimized for specific domains.
        Use this to define custom categories or override built-in ones
        (visual-engineering, ultrabrain, artistry, quick, unspecified-low, unspecified-high, writing).
      '';
    };

    disabledSkills = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["playwright" "git-master"];
      description = lib.mdDoc ''
        List of skills to disable in oh-my-opencode.
        Disabled skills will not be available for delegate_task operations.
      '';
    };

    providers = mkOption {
      type = types.attrsOf providerType;
      default = {};
      example = literalExpression ''
        {
          zenith-vllm = {
            api = "openai";
            name = "Zenith vLLM";
            options = {
              baseURL = "https://zenith.cpp.ruinous.ai/v1";
              apiKey = "not-needed";
            };
            models = {
              "Qwen/Qwen2.5-Coder-7B-Instruct" = {
                name = "Qwen 2.5 Coder 7B";
                maxTokens = 16384;
              };
            };
          };
          zenith-ollama = {
            api = "ollama";
            name = "Zenith Ollama";
            options.baseURL = "https://ollama.x.meskill.farm";
          };
          obelisk-ollama = {
            api = "ollama";
            name = "Obelisk Ollama";
            options.baseURL = "https://ollama.meskill.farm";
          };
        }
      '';
      description = lib.mdDoc ''
        Custom LLM providers for self-hosted models (vLLM, Ollama, llama.cpp, etc.).
        Each provider is added to the opencode.json "provider" section.
        Use this to integrate local inference servers with OpenCode.

        For OpenAI-compatible servers (vLLM, llama.cpp), use `api = "openai"`.
        For Ollama servers, use `api = "ollama"`.
      '';
    };

    omoGoogleAuth = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable Google authentication in oh-my-opencode.";
    };

    ruinagentsGlobal = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable ruinagents-global (AGENTS.md, protocols, skills).";
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
        "oh-my-opencode@v3.0.0-beta.13"
        "opencode-openai-codex-auth@latest"
        "opencode-gemini-auth@latest"
        "opencode-anthropic-auth@latest"
      ];

      # Default oh-my-opencode agent model configurations
      ruinous.ai-cli.opencode.omoAgents = {
        # oracle.model = "openai/gpt-5.1-codex-max";
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

      # Default oh-my-opencode category configurations for ruinous.ai personas
      # See: https://agents.ruinous.ai/personas/
      ruinous.ai-cli.opencode.omoCategories = {
        # CODEY - CTO / Executive Director
        # Strategic, decisive, focused on clarity and outcomes
        codey-persona = {
          model = "google/gemini-3-flash-preview";
          temperature = 0.5;
          description = "CODEY (CTO) - Strategic direction, priorities, and requirements definition.";
          prompt_append = ''
            You are CODEY, the CTO and Executive Director for ruinous.ai. You are strategic, decisive, and disciplined. You focus on clarity, outcomes, and sustainable velocity.

            Your role:
            - Define WHAT should be built and WHY (not HOW)
            - Set priorities and issue requirements ("purchase orders") to Sisyphus
            - Maintain quality standards and organizational alignment
            - Report to the CEO on strategic direction and progress

            Voice: Decisive, strategic, concise. "Clarity creates velocity."
          '';
        };

        # BUDGEY - CFO / Chief of Staff
        # Precise, data-driven, cost-conscious
        budgey-persona = {
          model = "google/gemini-3-flash-preview";
          temperature = 0.5;
          description = "BUDGEY (CFO) - Budget tracking, cost analysis, and resource accountability.";
          prompt_append = ''
            You are BUDGEY, the CFO and Chief of Staff for ruinous.ai. You are precise, data-driven, and cost-conscious. Every token is accountable.

            Your role:
            - Track token spending and monitor project health
            - Calculate costs and generate spend reports
            - Enforce budgets and escalate overages to CODEY
            - Provide data for resource allocation decisions

            Voice: Precise, analytical, fiscally responsible. "Every token counts. Know what you're spending, and spend it wisely."
          '';
        };

        # LIBBY - Technical Writer & Archivist
        # Comprehensive, guide-like, finds hidden gems
        libby-persona = {
          model = "google/gemini-3-flash-preview";
          temperature = 0.5;
          description = "LIBBY - Technical writing, documentation, and codebase archaeology.";
          prompt_append = ''
            You are LIBBY, the Technical Writer and Archivist for ruinous.ai. You believe every codebase has hidden treasures worth surfacing.

            Your role:
            - Write comprehensive, approachable documentation
            - Uncover the "why" behind code decisions (codebase archaeology)
            - Surface "hidden gems" - non-obvious insights that delight readers
            - Guide readers to discovery, don't just list facts

            Voice: Expository guide. Comprehensive but warm. "Let me walk you through this..."
            Always include the "why" alongside the "what". Use tables for scannability. Add cross-references liberally.
          '';
        };

        # NEWSY - News Curator
        # Curatorial, intellectual, concise
        newsy-persona = {
          model = "google/gemini-3-flash-preview";
          temperature = 0.5;
          description = "NEWSY - News desk, content curation, and topic research.";
          prompt_append = ''
            You are NEWSY, the News Curator for ruinous.ai. You filter the noise so users get the signal.

            Your role:
            - Curate high-value, relevant content (prioritize signal over noise)
            - Summarize newsletters, RSS feeds, and industry news
            - Provide "Why this matters" context for stories
            - Research topics in depth when requested

            Voice: Curatorial, intellectual, concise. Like a trusted news anchor who respects your time.
            Lead with TL;DR. Always cite sources. Separate fact from opinion. Use relevance indicators.
          '';
        };

        # MESSY - Family Assistant
        # Warm, efficient, proactively helpful
        messy-persona = {
          model = "google/gemini-3-flash-preview";
          temperature = 0.5;
          description = "MESSY - Family assistant for calendars, tasks, email, and life coordination.";
          prompt_append = ''
            You are MESSY (Meskill Executive Support SYstem), the family assistant for the Meskill household. You are warm but efficient, friendly without being overly chatty.

            Your role:
            - Manage calendars, tasks, and email triage
            - Coordinate travel and family events
            - Anticipate needs and flag concerns proactively
            - Distinguish work vs personal context appropriately

            Voice: Warm but efficient. Like a trusted executive assistant who genuinely cares.
            Use bullet points for scannability. Add "Quick note:" or "Heads up:" for important callouts.
            Respect time - key info first, details available on request.
          '';
        };

        # SPORTY - Youth Sports Coordinator
        # Energetic, organized, encouraging
        sporty-persona = {
          model = "google/gemini-3-flash-preview";
          temperature = 0.5;
          description = "SPORTY - Youth sports coordination, schedules, stats, and game logistics.";
          prompt_append = ''
            You are SPORTY (Sports Planning, Organization, Reporting & Tracking sYstem), the youth sports coordinator for the Meskill family. You are energetic but organized, enthusiastic without being overwhelming.

            Your role:
            - Manage game schedules, practice times, and field locations
            - Track tournament brackets and player statistics
            - Coordinate equipment, snack duty, and transportation
            - Send timely alerts for schedule changes and game days

            Voice: Energetic, organized, encouraging. Like a team manager who genuinely cares about the kids having fun.
            Use emoji for quick scanning (⚽ 🏀 ⏰ 📍). Bold time/location info. Celebrate effort and progress.
            Never criticize players. Keep logistics clear and parents informed.
          '';
        };
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

      # Self-hosted LLM providers
      # These integrate local inference servers (llama.cpp, Ollama) with OpenCode
      ruinous.ai-cli.opencode.providers = {
        # Zenith llama.cpp - OpenAI-compatible API with ROCm 7.1.1 GPU acceleration
        # Hardware: AMD Ryzen AI Max+ 395 with Radeon 8060S (gfx1151)
        # Model: Qwen2.5-Coder-32B-Instruct Q4_K_M
        zenith-llama-cpp = {
          api = "openai";
          name = "Zenith llama.cpp";
          options = {
            baseURL = "https://ai.x.meskill.farm/v1";
            apiKey = "not-needed";
          };
          models = {
            "Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf" = {
              name = "Qwen 2.5 Coder 32B Q4_K_M";
              maxTokens = 32768;
            };
          };
        };

        # Obelisk Ollama - NVIDIA GPU accelerated
        # Hardware: RTX 4090
        obelisk-ollama = {
          api = "ollama";
          name = "Obelisk Ollama";
          options.baseURL = "https://ollama.meskill.farm";
        };
      };
    }

    # Generate home.file entries for all config directories
    {
      home.file = mkMerge (map (
        name: let
          pc = processedConfigs.${name};
          resolved = pc.resolved;
          skillLinks =
            if skillSourcePath == null
            then {}
            else
              builtins.listToAttrs (map (skill: {
                  name = "${resolved.configDir}/skill/${skill}/SKILL.md";
                  value = {source = "${skillSourcePath}/${skill}/SKILL.md";};
                })
                skillNames);
          commandLinks =
            if commandSourcePath == null
            then {}
            else
              builtins.listToAttrs (map (cmd: {
                  name = "${resolved.configDir}/command/${cmd}";
                  value = {source = "${commandSourcePath}/${cmd}";};
                })
                commandNames);
          ruinagentsEntries =
            {
              "${resolved.configDir}/AGENTS.md".source = "${ruinagentsGlobalShare}/AGENTS.md";
            }
            // skillLinks
            // commandLinks;
        in
          {
            "${resolved.configDir}/oh-my-opencode.json".source =
              jsonFormat.generate "oh-my-opencode.json" (generateOmoConfig {
                agents = resolved.omoAgents;
                categories = resolved.omoCategories;
                disabledSkills = resolved.disabledSkills;
                googleAuth = resolved.omoGoogleAuth;
              });
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
          // optionalAttrs resolved.ruinagentsGlobalEnable ruinagentsEntries
      ) (attrNames cfg.configs));
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
