# ruinous.ai-cli.opencode.enable = true;
#
# Manages OpenCode CLI configuration with:
# - Main config (plugins, providers) synced via home-manager
# - oh-my-opencode agent configuration synced via home-manager
# - OAuth/API credentials encrypted with agenix (optional)
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
      default = [
        "oh-my-opencode"
        "opencode-openai-codex-auth"
        "opencode-gemini-auth@latest"
      ];
      description = "List of OpenCode plugins to install.";
    };

    notifier = {
      enable = mkEnableOption "OpenCode Apprise notification plugin";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Always sync public configs
    {
      # Main OpenCode config
      xdg.configFile."opencode/opencode.json".source = opencode_config;

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
          if command -v ${pkgs.bun}/bin/bun &> /dev/null; then
            $DRY_RUN_CMD ${pkgs.bun}/bin/bun install --cwd ${config.xdg.configHome}/opencode --silent 2>/dev/null || true
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
      home.activation.opencode-notifier-plugin =
        lib.hm.dag.entryAfter ["writeBoundary"] ''
          $DRY_RUN_CMD mkdir -p "${config.xdg.configHome}/opencode/plugin"
          $DRY_RUN_CMD cp -f "${pkgs.opencode-notifier-apprise}/share/opencode-notifier-apprise/plugin.js" \
            "${config.xdg.configHome}/opencode/plugin/apprise-notifier.js"
        '';
    })
  ]);
}
