# ruinous.ai-cli.opencode.enable = true;
#
# Manages OpenCode CLI configuration with:
# - CLI binary installation (Linux only, use brew on macOS)
# - Main config (plugins, providers) synced via home-manager
# - oh-my-opencode agent configuration synced via home-manager
# - Automatic plugin installation via activation script
# - Local plugin support (e.g., opencode-notifier-apprise)
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
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          type = mkOption {
            type = types.enum [ "local" "remote" ];
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
        };
      }));
      default = {};
      example = lib.mdDoc ''
        # Add a remote server
        ruinous.ai-cli.opencode.mcpServers.my-remote-server = {
          type = "remote";
          url = "https://example.com/mcp";
        };

        # Add a local server
        ruinous.ai-cli.opencode.mcpServers.my-local-server = {
          type = "local";
          command = [ "node" "/path/to/script.js" ];
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
  };

  config = mkIf cfg.enable (mkMerge [
    # Install opencode and sync configs
    {
      assertions = lib.mapAttrsToList (name: server: {
        assertion = (server.type == "remote" -> server.url != null) && (server.type == "local" -> server.command != null);
        message = "A remote MCP server must have a 'url' and a local server must have a 'command' for ''${name}'.";
      }) cfg.mcpServers;

      # Install opencode binary (Linux only - use brew on macOS)
      home.packages = mkIf pkgs.stdenv.isLinux [
        llmAgentsPkgs.opencode
      ];

      ruinous.ai-cli.opencode.plugins = [
        "oh-my-opencode@v2.14.0"
        "opencode-openai-codex-auth@latest"
        "opencode-gemini-auth@latest"
      ];

      ruinous.ai-cli.opencode.mcpServers = {
        todoist = {
          type = "local";
          command = ["bunx" "-y" "mcp-remote" "https://ai.todoist.net/mcp"];
        };
      };

      # oh-my-opencode agent configuration
      xdg.configFile."opencode/oh-my-opencode.json".source = omo_config;

      # package.json for plugin management
      xdg.configFile."opencode/package.json".text = builtins.toJSON {
        name = "opencode-plugins";
        dependencies = builtins.listToAttrs (
          map (plugin: let
            # Handle versioned plugins like "foo@latest"
            parts = lib.splitString "@" plugin;
            name = builtins.head parts;
            version =
              if builtins.length parts > 1
              then builtins.elemAt parts 1
              else "latest";
          in {
            inherit name;
            value = version;
          })
          cfg.plugins
        );
      };

      # Activation script to install plugins
      home.activation.opencode-plugins = mkIf cfg.installPlugins (
        lib.hm.dag.entryAfter ["writeBoundary"] ''
          CONFIG_DIR="${config.xdg.configHome}/opencode"
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
              --argjson new_plugins '${builtins.toJSON cfg.plugins}' \
              --argjson new_servers '${builtins.toJSON cfg.mcpServers}' \
              '
                # Ensure top-level keys exist
                .plugin //= []
                | .mcp = (.mcp // {}) + $new_servers
                # Reduce over new plugins to update or add them
                | reduce ($new_plugins[]) as $p (.;
                    ( $p | split("@")[0] ) as $name
                    # Find index of existing plugin by name
                    | (.plugin | map((. | split("@")[0]) == $name) | index(true)) as $idx
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

          if command -v ${pkgs.bun}/bin/bun &> /dev/null; then
            $DRY_RUN_CMD ${pkgs.bun}/bin/bun install --cwd "$CONFIG_DIR" --silent 2>/dev/null || true
          fi
        ''
      );
    }

    # Optionally enable Apprise notifier plugin
    (mkIf cfg.notifier.enable {
      # Add apprise-notify CLI tool to PATH
      home.packages = [pkgs.opencode-notifier-apprise];

      # Copy plugin.js to OpenCode plugin directory
      # OpenCode auto-discovers *.js files in ~/.config/opencode/plugin/
      home.activation.opencode-notifier-plugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p "${config.xdg.configHome}/opencode/plugin"
        $DRY_RUN_CMD cp -f "${pkgs.opencode-notifier-apprise}/share/opencode-notifier-apprise/plugin.js" \
          "${config.xdg.configHome}/opencode/plugin/apprise-notifier.js"
      '';
    })
  ]);
}
