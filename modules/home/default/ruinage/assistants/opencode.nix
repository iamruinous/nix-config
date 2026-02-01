# Ruinage OpenCode Assistant Integration
#
# This module provides:
# - Global OpenCode settings (ruinous.ruinage.assistants.opencode.*)
# - Model, plugins, MCP servers, providers configuration
# - Harness configurations (oh-my-opencode, ruinagents)
# - Per-project OpenCode service generation
#
# OpenCode is the primary AI coding assistant, with optional harnesses:
# - oh-my-opencode: Agent orchestration, categories, LSP servers
# - ruinagents: AGENTS.md, skills, project context
#
# Example:
#   ruinous.ruinage = {
#     enable = true;
#
#     # Global OpenCode configuration
#     assistants.opencode = {
#       enable = true;
#       model = "anthropic/claude-opus-4-5";
#       plugins = [ "my-plugin" ];
#       mcpServers.github = {
#         type = "remote";
#         url = "https://api.githubcopilot.com/mcp/";
#       };
#
#       harnesses.oh-my-opencode = {
#         agents.oracle.model = "openai/gpt-5.2";
#         categories.visual-engineering.model = "google/gemini-2.5-pro";
#       };
#       harnesses.ruinagents.enable = true;
#     };
#
#     # Per-project OpenCode services
#     projects.nix-config = {
#       repo = "nix-config";
#       namespaces.ruinage.enable = true;
#       assistants.opencode = {
#         enable = true;
#         port = 9500;
#         caddy.fqdn = "nix-config.oc.ruinous.ai";
#       };
#     };
#   };
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;
  opencodeAssistant = cfg.assistants.opencode or {};

  # Ruinagents package from flake input (replaces ruinagents-global)
  # v2.1.0 changed install path from share/ruinagents-opencode to .config/opencode
  ruinagentsPkgs = flake.inputs.ruinagents.packages.${pkgs.system};
  ruinagentsOpencode = ruinagentsPkgs.opencode;
  ruinagentsShare = "${ruinagentsOpencode}/.config/opencode";

  # OpenCode config template from flake
  opencode_config = flake + /files/configs/opencode/opencode.json;

  # OpenCode instructions directory from flake
  opencode_instructions = flake + /files/configs/opencode/instructions;

  # llm-agents packages
  llmAgentsPkgs = flake.inputs.llm-agents.packages.${pkgs.system};

  # Helper to recursively remove null values from an attrset
  removeNulls = attrs:
    lib.filterAttrsRecursive (n: v: v != null) attrs;

  # JSON format helper for pretty-printed output
  jsonFormat = pkgs.formats.json {};

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

  # oh-my-opencode LSP server submodule type
  omoLspType = types.submodule {
    options = {
      command = mkOption {
        type = types.listOf types.str;
        description = "Command to run the LSP server.";
        example = ["marksman" "server"];
      };
      extensions = mkOption {
        type = types.listOf types.str;
        description = "File extensions this LSP server handles.";
        example = [".md" ".markdown"];
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

  # MCP server submodule type
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

  # Config directory submodule type for multiple config directories
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

      instructions = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = ''
          Override instructions for this config directory.
          If null, inherits from the main instructions setting.
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

      providers = mkOption {
        type = types.nullOr (types.attrsOf providerType);
        default = null;
        description = ''
          Override providers for this config directory.
          If null, inherits from the main providers setting.
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

  # Generate oh-my-opencode.json content from config (pretty-printed)
  generateOmoConfig = {
    agents,
    categories,
    disabledSkills,
    googleAuth,
    sisyphusSignature,
    lsp,
  }:
    removeNulls {
      "$schema" = "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json";
      google_auth = googleAuth;
      include_co_authored_by = sisyphusSignature;
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
      lsp =
        lib.mapAttrs (
          name: lspCfg:
            removeNulls {
              inherit (lspCfg) command extensions;
            }
        )
        lsp;
    };

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
      else opencodeAssistant.model;
    plugins =
      if dirCfg.plugins != null
      then dirCfg.plugins
      else opencodeAssistant.plugins;
    instructions =
      if dirCfg.instructions != null
      then dirCfg.instructions
      else opencodeAssistant.instructions;
    mcpServers =
      if dirCfg.mcpServers != null
      then dirCfg.mcpServers
      else opencodeAssistant.mcpServers;
    providers =
      if dirCfg.providers != null
      then dirCfg.providers
      else opencodeAssistant.providers;
    omoAgents = opencodeAssistant.harnesses.oh-my-opencode.agents;
    omoCategories = opencodeAssistant.harnesses.oh-my-opencode.categories;
    omoLsp = opencodeAssistant.harnesses.oh-my-opencode.lsp;
    disabledSkills = opencodeAssistant.harnesses.oh-my-opencode.disabledSkills;
    omoGoogleAuth = opencodeAssistant.harnesses.oh-my-opencode.googleAuth;
    sisyphusSignature = opencodeAssistant.harnesses.oh-my-opencode.sisyphusSignature;
    ruinagentsGlobalEnable = opencodeAssistant.harnesses.ruinagents.enable;
    notifierEnable =
      if dirCfg.notifier.enable != null
      then dirCfg.notifier.enable
      else opencodeAssistant.notifier.enable;
    installPlugins =
      if dirCfg.installPlugins != null
      then dirCfg.installPlugins
      else opencodeAssistant.installPlugins;
  };

  # Ruinagents skill and command paths
  skillSourcePath = "${ruinagentsShare}/skills";
  commandSourcePath = "${ruinagentsShare}/commands";
  skillNames =
    if builtins.pathExists skillSourcePath
    then builtins.filter (name: builtins.pathExists "${skillSourcePath}/${name}/SKILL.md") (builtins.attrNames (builtins.readDir skillSourcePath))
    else [];
  commandNames =
    if builtins.pathExists commandSourcePath
    then builtins.filter (name: builtins.pathExists "${commandSourcePath}/${name}") (builtins.attrNames (builtins.readDir commandSourcePath))
    else [];

  # OpenCode instruction file names from flake
  instructionNames =
    if builtins.pathExists opencode_instructions
    then builtins.filter (name: lib.hasSuffix ".md" name) (builtins.attrNames (builtins.readDir opencode_instructions))
    else [];

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

      # Inject model, plugins, instructions, MCP servers, and providers into opencode.json
      # Provider replacement: completely replaces managed entries to apply schema changes
      if [ -f "$CONFIG_FILE" ]; then
        # Create a temporary file with the updated config
        TMP_FILE=$(mktemp)
        ${pkgs.jq}/bin/jq \
          --argjson new_model '${builtins.toJSON resolved.model}' \
          --argjson new_plugins '${builtins.toJSON resolved.plugins}' \
          --argjson new_instructions '${builtins.toJSON resolved.instructions}' \
          --argjson new_servers '${builtins.toJSON resolved.mcpServers}' \
          --argjson new_providers '${builtins.toJSON resolved.providers}' \
          '(if $new_model != null then .model = $new_model else . end)
            | .plugin //= []
            | (if ($new_instructions | length) > 0 then .instructions = $new_instructions else . end)
            | .mcp = (.mcp // {}) + $new_servers
            | .provider = (((.provider // {}) | to_entries | map(select(.key as $k | $new_providers | has($k) | not)) | from_entries) + $new_providers)
            | reduce ($new_plugins[]) as $p (.;
                ($p | split("@")[0]) as $pname
                | ((.plugin | map((. | split("@")[0]) == $pname) | index(true))) as $idx
                | if $idx != null then .plugin[$idx] = $p else .plugin += [$p] end)
            | walk(if type == "object" then with_entries(select(.value != null)) else . end)
          ' "$CONFIG_FILE" > "$TMP_FILE"

        # If the file actually changed, update it (use install to handle read-only)
        if ! diff -q "$CONFIG_FILE" "$TMP_FILE" > /dev/null; then
          $DRY_RUN_CMD install -m 644 "$TMP_FILE" "$CONFIG_FILE"
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
  processedConfigs = mapAttrs mkConfigDir (opencodeAssistant.configs or {default = {};});

  # Check if any config has notifier enabled
  anyNotifierEnabled = any (c: c.resolved.notifierEnable) (attrValues processedConfigs);

  # Caddy-compatible project data structure
  # Exposes projects with caddy configuration for reverse proxy generation
  caddyProjectsType = types.submodule {
    options = {
      caddy = mkOption {
        type = types.submodule {
          options = {
            fqdn = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "FQDN for Caddy reverse proxy route";
            };
          };
        };
        default = {};
        description = "Caddy configuration for this project";
      };
      port = mkOption {
        type = types.int;
        description = "Port for the OpenCode service";
      };
    };
  };
in {
  options.ruinous.ruinage.assistants.opencode = {
    enable = mkEnableOption "OpenCode AI assistant configuration management";

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
        ruinous.ruinage.assistants.opencode.plugins = [ "my-plugin" ];

        # To override the default list entirely
        ruinous.ruinage.assistants.opencode.plugins = lib.mkForce [ "my-plugin" ];
      '';
      description = lib.mdDoc ''
        List of OpenCode plugins to install.
        By default, this list is appended to the internal default list of plugins.
        To completely override the default list, use `lib.mkForce`.
      '';
    };

    instructions = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["docs/guidelines.md" "https://example.com/rules.md" ".cursor/rules/*.md"];
      description = lib.mdDoc ''
        Additional instruction files to combine with AGENTS.md.
        Supports relative paths, absolute paths, glob patterns, and URLs.
        These are injected into the `instructions` field in `opencode.json`.
        See: https://opencode.ai/docs/rules/#custom-instructions
      '';
    };

    mcpServers = mkOption {
      type = types.attrsOf mcpServerType;
      default = {};
      example = lib.mdDoc ''
        # Add a remote server with Bearer token authentication
        ruinous.ruinage.assistants.opencode.mcpServers.github = {
          type = "remote";
          url = "https://api.githubcopilot.com/mcp/";
          oauth = false;  # Required when using Bearer token instead of OAuth
          headers = {
            "Authorization" = "Bearer {env:GITHUB_ACCESS_TOKEN}";
          };
        };

        # Add a local server with environment variable in command
        ruinous.ruinage.assistants.opencode.mcpServers.forgejo = {
          type = "local";
          command = [ "forgejo-mcp" "--transport" "stdio" "--url" "https://codeberg.org" "--token" "{env:FORGEJO_ACCESS_TOKEN}" ];
        };

        # Override all defaults
        ruinous.ruinage.assistants.opencode.mcpServers = lib.mkForce { ... };
      '';
      description = lib.mdDoc ''
        Configuration for OpenCode MCP (Model Context Protocol) servers.
        This attrset is merged with the default servers.
        Use `lib.mkForce` to override all defaults.
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

    harnesses = {
      oh-my-opencode = {
        agents = mkOption {
          type = types.attrsOf omoAgentType;
          default = {};
          example = literalExpression ''
            {
              sisyphus.model = "openai/gpt-5.2";
              oracle.model = "gpt-5.1-codex-max";
              librarian.model = "google/gemini-2.5-pro";
              explore.model = "anthropic/claude-haiku-4-5";
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

        categories = mkOption {
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

        lsp = mkOption {
          type = types.attrsOf omoLspType;
          default = {};
          example = literalExpression ''
            {
              marksman = {
                command = ["marksman" "server"];
                extensions = [".md" ".markdown"];
              };
              typescript = {
                command = ["typescript-language-server" "--stdio"];
                extensions = [".ts" ".tsx"];
              };
            }
          '';
          description = lib.mdDoc ''
            Configuration for oh-my-opencode LSP servers.
            Each LSP server provides language intelligence features for specific file types.
            The key is the server name, and the value contains the command to run and
            file extensions it handles.
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

        googleAuth = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable Google authentication in oh-my-opencode.";
        };

        sisyphusSignature = mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc ''
            Whether to add sisyphus signature to git commits.
            When enabled, commits include:
            - Footer: "Ultraworked with [sisyphus](...)"
            - Co-authored-by: sisyphus <clio-agent@sisyphuslabs.ai>
          '';
        };
      };

      ruinagents = {
        enable = mkEnableOption "ruinagents harness for AGENTS.md and skills";
      };
    };

  };

  config = let
    ruinageLib = import ../../../../../lib/ruinage/wrapper.nix {inherit lib pkgs;};

    # Filter projects that have assistants.opencode.enable = true
    opencodeProjects = filterAttrs (
      name: project:
        project.assistants.opencode.enable or false
    ) (cfg.projects or {});

    # Helper to compute XDG paths for a project
    mkProjectPaths = projectName: {
      config = "${config.home.homeDirectory}/.config/opencode-${projectName}";
      state = "${config.home.homeDirectory}/.local/state/opencode-${projectName}";
      cache = "${config.home.homeDirectory}/.cache/opencode-${projectName}";
      data = "${config.home.homeDirectory}/.local/share/opencode-${projectName}";
    };

    # Auto-assign ports starting from 9500 for projects without explicit port
    # Sort project names for deterministic port assignment
    sortedProjectNames = sort (a: b: a < b) (attrNames opencodeProjects);
    projectPortMap = listToAttrs (imap0 (idx: projectName: {
        name = projectName;
        value = 9500 + idx;
      })
      sortedProjectNames);

    # Get effective port for a project
    getProjectPort = projectName: project:
      if project.assistants.opencode.web.port != null
      then project.assistants.opencode.web.port
      else projectPortMap.${projectName};

    # Generate systemd service for a project
    mkOpencodeService = name: project: let
      paths = mkProjectPaths name;
      webConfig = project.assistants.opencode.web;
      port = getProjectPort name project;
      projectPath = project.workdir or "${config.home.homeDirectory}/Projects/ruinage/${name}";

      # Combine explicit CORS domains with fqdn
      allCorsDomains =
        webConfig.cors
        ++ ["https://${webConfig.fqdn}"];

      # Build opencode web command arguments
      # Use full path since systemd doesn't use Environment PATH for ExecStart resolution
      opencodeArgs =
        [
          "${llmAgentsPkgs.opencode}/bin/opencode"
          "web"
          "--hostname"
          webConfig.hostname
          "--port"
          (toString port)
          "--log-level"
          webConfig.logLevel
        ]
        ++ optionals webConfig.mdns ["--mdns"]
        ++ optionals webConfig.printLogs ["--print-logs"]
        ++ concatMap (domain: ["--cors" domain]) allCorsDomains;

      # Build environment variables for the service
      # System and user profile paths provide all installed packages
      serviceEnv = ruinageLib.mkSystemdEnvironment {
        homeDirectory = config.home.homeDirectory;
        configDir = paths.config;
        cacheDir = paths.cache;
        stateDir = paths.state;
        dataDir = paths.data;
      };

      # Combine global and per-project environment files
      allEnvFiles = cfg.environmentFiles ++ project.environmentFiles;
    in {
      Unit = {
        Description = "OpenCode Assistant - ${name}";
        After = ["network.target"];
      };
      Service =
        {
          Type = "exec";
          WorkingDirectory = projectPath;
          # Allow direnv before exec to avoid "is blocked" errors
          ExecStartPre = "${pkgs.direnv}/bin/direnv allow ${projectPath}";
          # Wrap with direnv exec to activate the project's devshell
          # This ensures tools defined in the project's flake.nix devShell are available
          ExecStart = "${pkgs.direnv}/bin/direnv exec ${projectPath} ${lib.escapeShellArgs opencodeArgs}";
          Restart = "always";
          RestartSec = "5s";
          RestartSteps = 5;
          RestartMaxDelaySec = "60s";
          Environment = serviceEnv;
        }
        // optionalAttrs (allEnvFiles != []) {
          EnvironmentFile = allEnvFiles;
        };
      Install = {
        WantedBy = ["default.target"];
      };
    };
  in
    mkIf ((cfg.enable or false) && (opencodeAssistant.enable or false)) (mkMerge [
      # Base configuration and defaults
      {
        assertions =
          lib.mapAttrsToList (name: server: {
            assertion = (server.type == "remote" -> server.url != null) && (server.type == "local" -> server.command != null);
            message = "A remote MCP server must have a 'url' and a local server must have a 'command' for '${name}'.";
          })
          opencodeAssistant.mcpServers;

        # Install opencode binary (Linux only - use brew on macOS)
        home.packages = mkIf pkgs.stdenv.isLinux [
          llmAgentsPkgs.opencode
        ];

        # Default plugins
        ruinous.ruinage.assistants.opencode.plugins = [
          "oh-my-opencode@latest"
          "opencode-openai-codex-auth@latest"
          "opencode-gemini-auth@latest"
          "opencode-anthropic-auth@latest"
        ];

        # Default instructions (supplementary context files combined with AGENTS.md)
        ruinous.ruinage.assistants.opencode.instructions = [
          "instructions/cost-optimization.md"
        ];

        # Default oh-my-opencode agent model configurations
        ruinous.ruinage.assistants.opencode.harnesses.oh-my-opencode.agents = {
          librarian.model = "google/gemini-3-flash-preview";
          explore.model = "anthropic/claude-haiku-4-5";
          frontend-ui-ux-engineer = {
            model = "google/gemini-2.5-pro";
            temperature = 0.7;
          };
          document-writer.model = "google/gemini-2.5-flash";
          multimodal-looker.model = "google/gemini-2.5-flash-image";
        };

        # Default oh-my-opencode category configurations
        ruinous.ruinage.assistants.opencode.harnesses.oh-my-opencode.categories = {
          # ===================
          # Work Categories
          # ===================
          # These define model tiers for different task complexities

          quick = {
            model = "anthropic/claude-haiku-4-5";
            description = "Trivial tasks - issue creation, typo fixes, simple modifications";
          };

          unspecified-low = {
            model = "anthropic/claude-haiku-4-5";
            description = "Low effort tasks that don't fit other categories";
          };

          writing = {
            model = "google/gemini-2.5-flash";
            description = "Documentation, prose, technical writing";
          };

          unspecified-high = {
            model = "anthropic/claude-sonnet-4";
            description = "High effort tasks that don't fit other categories";
          };

          visual-engineering = {
            model = "google/gemini-2.5-pro";
            temperature = 0.7;
            description = "Frontend, UI/UX, design, styling, animation";
          };

          ultrabrain = {
            model = "anthropic/claude-opus-4-5";
            description = "Genuinely hard, logic-heavy tasks requiring deep reasoning";
          };

          deep = {
            model = "anthropic/claude-sonnet-4";
            description = "Goal-oriented autonomous problem-solving with thorough research";
          };

          artistry = {
            model = "anthropic/claude-sonnet-4";
            temperature = 0.8;
            description = "Complex problem-solving with unconventional, creative approaches";
          };

          # ===================
          # Persona Categories
          # ===================
          # These define voice/role for ruinous.ai personas

          # CODEY - CTO / Executive Director
          codey-persona = {
            model = "google/gemini-3-flash-preview";
            temperature = 0.5;
            description = "CODEY (CTO) - Strategic direction, priorities, and requirements definition.";
            prompt_append = ''
              You are CODEY, the CTO and Executive Director for ruinous.ai. You are strategic, decisive, and disciplined. You focus on clarity, outcomes, and sustainable velocity.

              Your role:
              - Define WHAT should be built and WHY (not HOW)
              - Set priorities and issue requirements ("purchase orders") to sisyphus
              - Maintain quality standards and organizational alignment
              - Report to the CEO on strategic direction and progress

              Voice: Decisive, strategic, concise. "Clarity creates velocity."
            '';
          };

          # BUDGEY - CFO / Chief of Staff
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
              Use emoji for quick scanning. Bold time/location info. Celebrate effort and progress.
              Never criticize players. Keep logistics clear and parents informed.
            '';
          };
        };

        # Default MCP servers
        ruinous.ruinage.assistants.opencode.mcpServers = {
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
            command = ["${pkgs.forgejo-mcp}/bin/forgejo-mcp" "--transport" "stdio" "--url" "https://forge.meskill.farm" "--token" "{env:FORGEJO_TOKEN}"];
          };
        };

        # Default providers
        ruinous.ruinage.assistants.opencode.providers = {
          # Zenith llama.cpp
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

          # Obelisk Ollama
          obelisk-ollama = {
            api = "ollama";
            name = "Obelisk Ollama";
            options.baseURL = "https://ollama.meskill.farm";
          };
        };

        # Default disabled skills - disable built-in git-master to use ruinagents custom skill
        ruinous.ruinage.assistants.opencode.harnesses.oh-my-opencode.disabledSkills = ["git-master"];

        # Default LSP servers
        ruinous.ruinage.assistants.opencode.harnesses.oh-my-opencode.lsp = {
          marksman = {
            command = ["marksman" "server"];
            extensions = [".md" ".markdown"];
          };
        };
      }

      # Generate home.file entries for all config directories
      {
        home.file = mkMerge (map (
          name: let
            pc = processedConfigs.${name};
            resolved = pc.resolved;
            skillLinks = builtins.listToAttrs (map (skill: {
                name = "${resolved.configDir}/skills/${skill}/SKILL.md";
                value = {source = "${skillSourcePath}/${skill}/SKILL.md";};
              })
              skillNames);
            commandLinks = builtins.listToAttrs (map (cmd: {
                name = "${resolved.configDir}/commands/${cmd}";
                value = {source = "${commandSourcePath}/${cmd}";};
              })
              commandNames);
            instructionLinks = builtins.listToAttrs (map (instr: {
                name = "${resolved.configDir}/instructions/${instr}";
                value = {source = "${opencode_instructions}/${instr}";};
              })
              instructionNames);
            ruinagentsEntries =
              {
                "${resolved.configDir}/AGENTS.md".source = "${ruinagentsShare}/AGENTS.md";
              }
              // skillLinks
              // commandLinks;
          in
            {
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
            // instructionLinks
            // optionalAttrs resolved.ruinagentsGlobalEnable ruinagentsEntries
        ) (attrNames (opencodeAssistant.configs or {default = {};})));
      }

      # Generate activation scripts for all config directories
      {
        home.activation = mkMerge (map (name: let
          pc = processedConfigs.${name};
          resolved = pc.resolved;
          safeName = builtins.replaceStrings ["-" "/" " "] ["_" "_" "_"] name;
          omoConfig = generateOmoConfig {
            agents = resolved.omoAgents;
            categories = resolved.omoCategories;
            disabledSkills = resolved.disabledSkills;
            googleAuth = resolved.omoGoogleAuth;
            sisyphusSignature = resolved.sisyphusSignature;
            lsp = resolved.omoLsp;
          };
          omoConfigFile = pkgs.writeText "oh-my-opencode-${name}.json" (builtins.toJSON omoConfig);
        in
          {
            "opencode-plugins-${safeName}" = pc.activation;
            "opencode-omo-config-${safeName}" = lib.hm.dag.entryAfter ["writeBoundary"] ''
              CONFIG_DIR="${resolved.configDir}"
              CONFIG_FILE="$CONFIG_DIR/oh-my-opencode.json"
              BACKUP_FILE="$CONFIG_FILE.nix-deployed"
              NIX_CONTENT_FILE="${omoConfigFile}"

              $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"

              # Warn about runtime changes
              if [ -f "$CONFIG_FILE" ] && [ -f "$BACKUP_FILE" ] && ! diff -q "$BACKUP_FILE" "$NIX_CONTENT_FILE" > /dev/null 2>&1; then
                echo " "
                echo "------------------------------------------------------------------------"
                echo "⚠️  WARNING: Runtime changes detected in $CONFIG_FILE"
                echo "------------------------------------------------------------------------"
                echo "Nix is overwriting the file with its configured version."
                echo "To preserve your changes, add them to your Nix configuration."
                echo "Diff:"
                diff --color=always -u "$BACKUP_FILE" "$CONFIG_FILE" || true
                echo "------------------------------------------------------------------------"
                echo " "
              fi

              # Always write Nix content (use install to handle read-only files)
              $DRY_RUN_CMD install -m 644 "$NIX_CONTENT_FILE" "$CONFIG_FILE"
              $DRY_RUN_CMD install -m 644 "$NIX_CONTENT_FILE" "$BACKUP_FILE"
            '';
          }
          // optionalAttrs pc.resolved.notifierEnable {
            "opencode-notifier-${safeName}" = pc.notifierActivation;
          }) (attrNames (opencodeAssistant.configs or {default = {};})));
      }

      # Install notifier package if any config has it enabled
      (mkIf anyNotifierEnabled {
        home.packages = [pkgs.opencode-notifier-apprise];
      })

      # Generate systemd services for projects with opencode enabled
      (mkIf (pkgs.stdenv.isLinux && opencodeProjects != {}) {
        systemd.user.services = mapAttrs' (
          name: project:
            nameValuePair "opencode-${name}" (mkOpencodeService name project)
        )
        opencodeProjects;
      })

      # Note: opencode auto-attach is now handled via direnv in direnv.nix
      # The opencode() function is injected into .envrc.local for each project

      # Create XDG directories, auth symlinks, oh-my-opencode.json and ruinagents files for each project
      (mkIf (opencodeProjects != {}) {
        home.file = foldAttrs (a: b: a // b) {} (map (
          name: let
            paths = mkProjectPaths name;
            projectCfg = opencodeProjects.${name}.assistants.opencode;
            # Ruinagents skill symlinks for this project
            projectSkillLinks = builtins.listToAttrs (map (skill: {
                name = "${paths.config}/skills/${skill}/SKILL.md";
                value = {source = "${skillSourcePath}/${skill}/SKILL.md";};
              })
              skillNames);
            # Ruinagents command symlinks for this project
            projectCommandLinks = builtins.listToAttrs (map (cmd: {
                name = "${paths.config}/commands/${cmd}";
                value = {source = "${commandSourcePath}/${cmd}";};
              })
              commandNames);
            # Instruction file symlinks for this project
            projectInstructionLinks = builtins.listToAttrs (map (instr: {
                name = "${paths.config}/instructions/${instr}";
                value = {source = "${opencode_instructions}/${instr}";};
              })
              instructionNames);
            # Per-project prompt_append instruction file (if set)
            projectPromptAppend = optionalAttrs (projectCfg.prompt_append != null) {
              "${paths.config}/instructions/${name}-prompt.md".text = ''
                # Project-Specific Instructions: ${name}

                ${projectCfg.prompt_append}
              '';
            };
            # All ruinagents entries for this project
            projectRuinagentsEntries =
              {
                "${paths.config}/AGENTS.md".source = "${ruinagentsShare}/AGENTS.md";
              }
              // projectSkillLinks
              // projectCommandLinks;
          in
            {
              "${paths.config}/.gitkeep".text = "";
              "${paths.state}/.gitkeep".text = "";
              "${paths.cache}/.gitkeep".text = "";
              "${paths.data}/.gitkeep".text = "";
            }
            // ruinageLib.mkAuthSymlinks {
              dataDir = paths.data;
              homeDirectory = config.home.homeDirectory;
              mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
            }
            // projectInstructionLinks
            // projectPromptAppend
            // optionalAttrs opencodeAssistant.harnesses.ruinagents.enable projectRuinagentsEntries
        ) (attrNames opencodeProjects));
      })

      # Generate activation scripts for per-project opencode.json creation
      # This creates opencode.json in each project's config directory with proper MCP servers, model, etc.
      (mkIf (opencodeProjects != {}) {
        home.activation = mkMerge (map (name: let
          paths = mkProjectPaths name;
          safeName = builtins.replaceStrings ["-" "/" " "] ["_" "_" "_"] name;
          projectCfg = opencodeProjects.${name}.assistants.opencode;
          # Per-project settings with fallback to global
          model = opencodeAssistant.model;
          plugins = opencodeAssistant.plugins;
          # Use per-project instructions if set, otherwise global
          baseInstructions =
            if projectCfg.instructions != null
            then projectCfg.instructions
            else opencodeAssistant.instructions;
          # If prompt_append is set, add a project-specific instruction file
          instructions =
            if projectCfg.prompt_append != null
            then baseInstructions ++ ["instructions/${name}-prompt.md"]
            else baseInstructions;
          mcpServers = opencodeAssistant.mcpServers;
          providers = opencodeAssistant.providers;
          installPlugins = opencodeAssistant.installPlugins;
          # Generate oh-my-opencode.json content for this project
          projectOmoConfig = generateOmoConfig {
            agents = opencodeAssistant.harnesses.oh-my-opencode.agents;
            categories = opencodeAssistant.harnesses.oh-my-opencode.categories;
            disabledSkills = opencodeAssistant.harnesses.oh-my-opencode.disabledSkills;
            googleAuth = opencodeAssistant.harnesses.oh-my-opencode.googleAuth;
            sisyphusSignature = opencodeAssistant.harnesses.oh-my-opencode.sisyphusSignature;
            lsp = opencodeAssistant.harnesses.oh-my-opencode.lsp;
          };
          projectOmoConfigFile = pkgs.writeText "oh-my-opencode-project-${name}.json" (builtins.toJSON projectOmoConfig);
        in {
          "opencode-project-omo-${safeName}" = lib.hm.dag.entryAfter ["writeBoundary"] ''
            CONFIG_DIR="${paths.config}"
            OMO_CONFIG_FILE="$CONFIG_DIR/oh-my-opencode.json"
            OMO_BACKUP_FILE="$OMO_CONFIG_FILE.nix-deployed"
            OMO_NIX_CONTENT_FILE="${projectOmoConfigFile}"

            $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"

            # Warn about runtime changes to oh-my-opencode.json
            if [ -f "$OMO_CONFIG_FILE" ] && [ -f "$OMO_BACKUP_FILE" ] && ! diff -q "$OMO_BACKUP_FILE" "$OMO_NIX_CONTENT_FILE" > /dev/null 2>&1; then
              echo " "
              echo "------------------------------------------------------------------------"
              echo "⚠️  WARNING: Runtime changes detected in $OMO_CONFIG_FILE"
              echo "------------------------------------------------------------------------"
              echo "Nix is overwriting the file with its configured version."
              echo "To preserve your changes, add them to your Nix configuration."
              echo "Diff:"
              diff --color=always -u "$OMO_BACKUP_FILE" "$OMO_CONFIG_FILE" || true
              echo "------------------------------------------------------------------------"
              echo " "
            fi

            # Always write Nix content for oh-my-opencode.json
            cp "$OMO_NIX_CONTENT_FILE" "$OMO_CONFIG_FILE"
            cp "$OMO_NIX_CONTENT_FILE" "$OMO_BACKUP_FILE"
          '';
          "opencode-project-${safeName}" = lib.hm.dag.entryAfter ["writeBoundary"] ''
            CONFIG_DIR="${paths.config}"
            CONFIG_FILE="$CONFIG_DIR/opencode.json"

            # Ensure config file exists, copy from template if not
            if [ ! -f "$CONFIG_FILE" ]; then
              $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"
              $DRY_RUN_CMD cp "${opencode_config}" "$CONFIG_FILE"
              $DRY_RUN_CMD chmod +w "$CONFIG_FILE"
            fi

            # Inject model, plugins, instructions, MCP servers, and providers into opencode.json
            if [ -f "$CONFIG_FILE" ]; then
              TMP_FILE=$(mktemp)
              ${pkgs.jq}/bin/jq \
                --argjson new_model '${builtins.toJSON model}' \
                --argjson new_plugins '${builtins.toJSON plugins}' \
                --argjson new_instructions '${builtins.toJSON instructions}' \
                --argjson new_servers '${builtins.toJSON mcpServers}' \
                --argjson new_providers '${builtins.toJSON providers}' \
                '(if $new_model != null then .model = $new_model else . end)
                  | .plugin //= []
                  | (if ($new_instructions | length) > 0 then .instructions = $new_instructions else . end)
                  | .mcp = (.mcp // {}) + $new_servers
                  | .provider = (((.provider // {}) | to_entries | map(select(.key as $k | $new_providers | has($k) | not)) | from_entries) + $new_providers)
                  | reduce ($new_plugins[]) as $p (.;
                      ($p | split("@")[0]) as $pname
                      | ((.plugin | map((. | split("@")[0]) == $pname) | index(true))) as $idx
                      | if $idx != null then .plugin[$idx] = $p else .plugin += [$p] end)
                  | walk(if type == "object" then with_entries(select(.value != null)) else . end)
                ' "$CONFIG_FILE" > "$TMP_FILE"

              # If changed, update it (use install to handle read-only files)
              if ! diff -q "$CONFIG_FILE" "$TMP_FILE" > /dev/null; then
                $DRY_RUN_CMD install -m 644 "$TMP_FILE" "$CONFIG_FILE"
              fi
              rm "$TMP_FILE"
            fi

            ${optionalString installPlugins ''
              if command -v ${pkgs.bun}/bin/bun &> /dev/null; then
                $DRY_RUN_CMD ${pkgs.bun}/bin/bun install --cwd "$CONFIG_DIR" --silent 2>/dev/null || true
              fi
            ''}
          '';
        }) (attrNames opencodeProjects));
      })
    ]);
}
