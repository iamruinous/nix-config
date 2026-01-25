# Ruinage OpenCode Assistant Integration
#
# This module provides:
# - Global OpenCode settings (ruinous.ruinage.assistants.opencode.*)
# - Harness configurations (oh-my-opencode, ruinagents)
# - Per-project OpenCode service generation
#
# OpenCode is the primary AI coding assistant, with optional harnesses:
# - oh-my-opencode: Agent orchestration, categories, LSP servers
# - ruinagents: AGENTS.md, skills, project context
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
  ruinagentsPkgs = flake.inputs.ruinagents.packages.${pkgs.system};
  ruinagentsOpencode = ruinagentsPkgs.opencode;
  ruinagentsShare = "${ruinagentsOpencode}/share/ruinagents-opencode";

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
     ruinageLib = import ../../../lib/ruinage/wrapper.nix { inherit lib pkgs; };
     
     # Filter projects that have assistants.opencode.enable = true
     opencodeProjects = filterAttrs (name: project: 
       project.assistants.opencode.enable or false
     ) (cfg.projects or {});
     
     # Helper to compute XDG paths for a project
     mkProjectPaths = projectName: {
       config = "${config.home.homeDirectory}/.config/opencode-${projectName}";
       state = "${config.home.homeDirectory}/.local/state/opencode-${projectName}";
       cache = "${config.home.homeDirectory}/.cache/opencode-${projectName}";
       data = "${config.home.homeDirectory}/.local/share/opencode-${projectName}";
     };
     
     # Determine effective port for a project (project-specific overrides top-level)
     getProjectPort = project: 
       if project.assistants.opencode.port != null
       then project.assistants.opencode.port
       else project.port;
     
     # Generate systemd service for a project
     mkOpencodeService = name: project: let
       paths = mkProjectPaths name;
       port = getProjectPort project;
       webConfig = project.assistants.opencode.web;
       caddyFqdn = project.assistants.opencode.caddy.fqdn;
       
       # Combine explicit CORS domains with caddy FQDN
       allCorsDomains = 
         webConfig.cors 
         ++ optionals (caddyFqdn != null) ["https://${caddyFqdn}"];
       
       # Build opencode web command arguments
       opencodeArgs = 
         [
           "opencode"
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
       serviceEnv = ruinageLib.mkSystemdEnvironment {
         homeDirectory = config.home.homeDirectory;
         extraPackages = cfg.packages;
         configDir = paths.config;
         cacheDir = paths.cache;
         stateDir = paths.state;
         dataDir = paths.data;
         includeSystemPath = true;
       };
     in {
       Unit = {
         Description = "OpenCode Assistant - ${name}";
         After = ["network.target"];
       };
       Service = {
         Type = "exec";
         WorkingDirectory = project.workdir or "${config.home.homeDirectory}/Projects/ruinage/${name}";
         ExecStart = "${lib.escapeShellArgs opencodeArgs}";
         Restart = "always";
         RestartSec = "5s";
         RestartSteps = 5;
         RestartMaxDelaySec = "60s";
         Environment = serviceEnv;
       };
       Install = {
         WantedBy = ["default.target"];
       };
     };
     
     # Generate fish function for auto-attach to running services
     mkOpencodeFishFunction = let
       caseEntries = concatStringsSep "\n    " (map (name: let
         project = opencodeProjects.${name};
         port = getProjectPort project;
       in ''
         case "${project.workdir or "${config.home.homeDirectory}/Projects/ruinage/${name}"}"
             # Project: ${name}
             set -lx OPENCODE_CONFIG_DIR "${(mkProjectPaths name).config}"
             set -lx XDG_CACHE_HOME "${(mkProjectPaths name).cache}"
             set -lx XDG_STATE_HOME "${(mkProjectPaths name).state}"
             set -lx XDG_DATA_HOME "${(mkProjectPaths name).data}"
             command opencode attach "http://localhost:${toString port}" $argv
             return'') (attrNames opencodeProjects));
     in ''
       # Auto-attach wrapper for opencode
       # If in a known project directory with a running service, attach to it
       # Otherwise, run opencode normally
       
       # If arguments are passed (like 'run', 'serve', etc.), run normally
       if test (count $argv) -gt 0
         command opencode $argv
         return
       end
       
       # Check if PWD matches a known project with service
       switch "$PWD"
           ${caseEntries}
       end
       
       # No match, run opencode normally
       command opencode $argv
     '';
   in mkIf ((cfg.enable or false) && (opencodeAssistant.enable or false)) {
     # Generate systemd services for projects with opencode enabled
     systemd.user.services = mkIf (pkgs.stdenv.isLinux && opencodeProjects != {}) (
       mapAttrs' (name: project:
         nameValuePair "opencode-${name}" (mkOpencodeService name project)
       ) opencodeProjects
     );
     
     # Generate fish function for auto-attach
     programs.fish.functions.opencode = mkIf (opencodeProjects != {}) {
       body = mkOpencodeFishFunction;
       description = "Auto-attach to OpenCode service or run normally";
     };
     
     # Create XDG directories for each project
     home.file = mkIf (opencodeProjects != {}) (
       foldAttrs (a: b: a // b) {} (map (name: let
         paths = mkProjectPaths name;
       in {
         "${paths.config}/.gitkeep".text = "";
         "${paths.state}/.gitkeep".text = "";
         "${paths.cache}/.gitkeep".text = "";
         "${paths.data}/.gitkeep".text = "";
       }) (attrNames opencodeProjects))
     );
   };

}
