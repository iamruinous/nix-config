# ruinous.ai-cli.opencode.enable = true;
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
  omo_config = flake + /files/configs/opencode/oh-my-opencode.json;
  llmAgentsPkgs = flake.inputs.llm-agents.packages.${pkgs.system};

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
    # xdg.configFile entries for this directory
    configFiles = {
      "${resolved.configDir}/oh-my-opencode.json" = {
        source = omo_config;
      };
      "${resolved.configDir}/package.json" = {
        text = builtins.toJSON {
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
      };
    };

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
        "oh-my-opencode@v3.0.0-beta.2"
        "opencode-openai-codex-auth@latest"
        "opencode-gemini-auth@latest"
        "opencode-anthropic-auth@0.0.7"
        # Patched version of anthropic-auth with tool renaming for OAuth
        # This bypasses the "credential only authorized for Claude Code" restriction
      ];

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
      in {
        "${resolved.configDir}/oh-my-opencode.json".source = omo_config;
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
