# ruinous.ai-cli.kimaki.enable = true;
#
# Manages Kimaki Discord bot service for controlling OpenCode agents.
# Kimaki connects Discord channels to OpenCode projects, allowing you to
# interact with coding agents via Discord messages and voice.
#
# FIRST-TIME SETUP (required before enabling the service):
#   1. Run `npx -y kimaki@latest` manually in a terminal
#   2. Follow the interactive setup wizard to:
#      - Create a Discord bot at discord.com/developers/applications
#      - Configure bot settings (Message Content, Server Members intents)
#      - Install the bot to your Discord server
#      - Select OpenCode projects to link as Discord channels
#      - Optionally set up voice features with a Gemini API key
#   3. Credentials are stored in ~/.kimaki/discord-sessions.db
#   4. After setup, enable the service for persistent operation
#
# Example:
#   ruinous.ai-cli.kimaki = {
#     enable = true;
#     # Uses llm-agents opencode by default; override if needed:
#     # opencodePackage = pkgs.opencode;
#     # Common MCP tools (uv, pnpm, nodejs, bun, gnumake) included by default
#     # Isolate state/cache from interactive opencode:
#     configDir = "${config.home.homeDirectory}/.config/kimaki";
#     cacheDir = "${config.home.homeDirectory}/.cache/kimaki";
#     stateDir = "${config.home.homeDirectory}/.local/state/kimaki";
#   };
#
# This creates a systemd user service `kimaki.service` that runs the
# Kimaki Discord bot. The service will restart automatically and use
# the credentials stored during interactive setup.
#
# ## Using agenix Environment Files (Linux only)
#
# You can pass encrypted environment files containing API keys and secrets to
# the kimaki service using the `environmentFiles` option. This uses systemd's
# EnvironmentFile directive to load variables at service startup.
#
# Example with agenix:
#
#   # In your home-configuration.nix or similar:
#   ruinous.ai-cli.kimaki = {
#     enable = true;
#     environmentFiles = [
#       config.age.secrets.opencode_common_env.path
#       config.age.secrets.kimaki_env.path
#     ];
#   };
#
#   # Declare the agenix secrets (in NixOS config or home-manager with agenix):
#   age.secrets.opencode_common_env = {
#     rekeyFile = ./files/opencode-web/common.env.age;
#     mode = "600";
#   };
#   age.secrets.kimaki_env = {
#     rekeyFile = ./files/kimaki/env.age;
#     mode = "600";
#   };
#
# Files are loaded in order, with later files overriding earlier ones.
#
# Note: kimaki is linux-only and requires systemd.
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ai-cli.kimaki;
  llmAgentsPkgs = flake.inputs.llm-agents.packages.${pkgs.system};

  # Import shared OpenCode library from top-level lib/
  opcodeLib = import ../../../../lib/opencode/wrapper.nix {inherit lib pkgs;};

  # Create a wrapped opencode with all necessary environment setup
  wrappedOpencode = opcodeLib.mkWrappedOpencode {
    package = cfg.opencodePackage;
    extraPackages = cfg.packages;
  };

  # Build the command to run kimaki via npx
  kimakiCommand =
    [
      "${pkgs.nodejs}/bin/npx"
      "-y"
      "kimaki@latest"
    ]
    ++ cfg.extraArgs;
in {
  options.ruinous.ai-cli.kimaki = {
    enable = mkEnableOption "Kimaki Discord bot for OpenCode control";

    opencodePackage = mkOption {
      type = types.package;
      default = llmAgentsPkgs.opencode;
      description = "The opencode package to use.";
      example = literalExpression "pkgs.opencode";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = opcodeLib.defaultPackages;
      description = ''
        Additional packages to include in the service PATH.
        Useful for MCP servers that need tools like uvx, pnpm, etc.
        Defaults to common MCP server dependencies (uv, pnpm, nodejs, bun, gnumake).
      '';
      example = literalExpression "with pkgs; [uv pnpm nodejs]";
    };

    workingDirectory = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}";
      description = "Working directory for the kimaki service.";
    };

    configDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Custom config directory for kimaki/opencode.
        When set, OPENCODE_CONFIG_DIR environment variable is set to this path,
        keeping service sessions independent from interactive opencode usage.
      '';
      example = "/home/user/.config/kimaki";
    };

    cacheDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Custom cache directory for the kimaki/opencode service.
        When set, XDG_CACHE_HOME environment variable is set to this path,
        keeping service cache independent from interactive opencode usage.
      '';
      example = "/home/user/.cache/kimaki";
    };

    stateDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Custom state directory for the kimaki/opencode service.
        When set, XDG_STATE_HOME environment variable is set to this path,
        keeping service state (logs, history) independent from interactive opencode usage.

        Authentication tokens are shared with interactive opencode via symlinks:
        - <stateDir>/opencode/auth.json -> ~/.local/state/opencode/auth.json
        - <stateDir>/opencode/mcp-auth.json -> ~/.local/state/opencode/mcp-auth.json
      '';
      example = "/home/user/.local/state/kimaki";
    };

    dataDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Custom data directory for the kimaki/opencode service.
        When set, XDG_DATA_HOME environment variable is set to this path,
        keeping service data (project registry) independent from interactive opencode usage.

        OpenCode stores registered projects in $XDG_DATA_HOME/opencode/storage/project/.
        When isolated, kimaki's opencode instances will have their own project registries.
      '';
      example = "/home/user/.local/share/kimaki";
    };

    includeSystemPath = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Include system and user profile paths in the service PATH.
        When enabled, adds /run/current-system/sw/bin and /etc/profiles/per-user/$USER/bin
        to PATH, giving access to all system and home-manager installed packages.
      '';
    };

    discordTokenSecret = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to an agenix-decrypted file containing the Discord bot token.
        NOTE: Kimaki currently stores credentials in ~/.kimaki/discord-sessions.db
        after interactive setup. This option sets DISCORD_TOKEN_FILE environment
        variable for potential future use or custom kimaki builds.
      '';
      example = literalExpression "config.age.secrets.kimaki_discord_token.path";
    };

    geminiApiKeySecret = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to an agenix-decrypted file containing the Google Gemini API key.
        Required for voice features (voice messages and voice channels).
        NOTE: Kimaki currently stores this in ~/.kimaki/discord-sessions.db
        after interactive setup. This option sets GEMINI_API_KEY_FILE environment
        variable for potential future use or custom kimaki builds.
      '';
      example = literalExpression "config.age.secrets.kimaki_gemini_api_key.path";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra arguments to pass to kimaki.";
      example = [];
    };

    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [];
      description = ''
        List of environment files to load into the service.
        Typically agenix secret paths like config.age.secrets.<name>.path.
        Variables in these files will be available to kimaki and child processes.
        Files are loaded in order, with later files overriding earlier ones.

        Note: kimaki is linux-only and requires systemd.
      '';
      example = literalExpression ''
        [
          config.age.secrets.opencode_common_env.path
          config.age.secrets.kimaki_env.path
        ]
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Ensure kimaki data directory exists and symlink opencode binary
    # Kimaki hardcodes the path ~/.opencode/bin/opencode, so we create a symlink
    {
      home.file.".kimaki/.keep".text = "";
      home.file.".opencode/bin/opencode".source = "${wrappedOpencode}/bin/opencode";
    }

    # Assertion for linux-only usage
    {
      assertions = [
        {
          assertion = pkgs.stdenv.isLinux;
          message = ''
            kimaki is linux-only (systemd user service).
          '';
        }
      ];
    }

    # Symlink shared auth files when using isolated stateDir
    (mkIf (cfg.stateDir != null) {
      home.file = opcodeLib.mkAuthSymlinks {
        stateDir = cfg.stateDir;
        homeDirectory = config.home.homeDirectory;
        mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
      };
    })

    # Linux: systemd user service
    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.kimaki = {
        Unit = {
          Description = "Kimaki Discord bot for OpenCode control";
          After = ["network.target"] ++ optionals (cfg.environmentFiles != []) ["agenix.service"];
          Requires = optionals (cfg.environmentFiles != []) ["agenix.service"];
        };
        Service =
          {
            Type = "exec";
            WorkingDirectory = cfg.workingDirectory;
            ExecStart = concatStringsSep " " kimakiCommand;
            Restart = "always";
            RestartSec = "5s";
            RestartSteps = 5;
            RestartMaxDelaySec = "60s";
            Environment = opcodeLib.mkSystemdEnvironment {
              homeDirectory = config.home.homeDirectory;
              extraPackages = cfg.packages;
              configDir = cfg.configDir;
              cacheDir = cfg.cacheDir;
              stateDir = cfg.stateDir;
              dataDir = cfg.dataDir;
              includeSystemPath = cfg.includeSystemPath;
              # Include wrapped opencode in PATH for child processes
              prependPaths = ["${wrappedOpencode}/bin"];
              extraEnv =
                [
                  # Node.js npm cache directory
                  "npm_config_cache=${config.home.homeDirectory}/.npm"
                ]
                ++ optionals (cfg.discordTokenSecret != null) [
                  "DISCORD_TOKEN_FILE=${cfg.discordTokenSecret}"
                ]
                ++ optionals (cfg.geminiApiKeySecret != null) [
                  "GEMINI_API_KEY_FILE=${cfg.geminiApiKeySecret}"
                ];
            };
          }
          // optionalAttrs (cfg.environmentFiles != []) {
            EnvironmentFile = cfg.environmentFiles;
          };
        Install = {
          WantedBy = ["default.target"];
        };
      };
    })
  ]);
}
