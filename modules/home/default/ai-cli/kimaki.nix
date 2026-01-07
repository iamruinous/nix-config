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
#   };
#
# This creates a systemd user service `kimaki.service` that runs the
# Kimaki Discord bot. The service will restart automatically and use
# the credentials stored during interactive setup.
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

  # Default packages for MCP server functionality
  defaultPackages = with pkgs; [
    uv # Provides uvx for Python-based MCP servers
    pnpm # For JavaScript-based MCP servers
    nodejs # Node.js runtime for MCP servers
    bun
    gnumake # postgres-mcp
  ];

  # Packages that are always needed for opencode functionality
  builtinPackages = with pkgs; [
    git # Git is essential for opencode's VCS operations
    openssh # SSH for git operations and signing
    nodejs # Node.js runtime for kimaki
  ];

  # Create a wrapped opencode with all necessary environment setup
  wrappedOpencode = pkgs.symlinkJoin {
    name = "opencode-wrapped";
    paths = [cfg.opencodePackage];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/opencode \
        --prefix PATH : ${lib.makeBinPath (builtinPackages ++ cfg.packages)} \
        --set NIX_LD /run/current-system/sw/share/nix-ld/lib/ld.so \
        --prefix NIX_LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]} \
        --prefix NIX_LD_LIBRARY_PATH : /run/current-system/sw/share/nix-ld/lib \
        --set OPENCODE_LIBC ${pkgs.glibc}/lib/libc.so.6
    '';
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
      default = defaultPackages;
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
  };

  config = mkIf cfg.enable (mkMerge [
    # Ensure kimaki data directory exists
    {
      home.file.".kimaki/.keep".text = "";
    }

    # Linux: systemd user service
    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.kimaki = {
        Unit = {
          Description = "Kimaki Discord bot for OpenCode control";
          After = ["network.target"];
        };
        Service = {
          Type = "exec";
          WorkingDirectory = cfg.workingDirectory;
          ExecStart = concatStringsSep " " kimakiCommand;
          Restart = "always";
          RestartSec = "5s";
          RestartSteps = 5;
          RestartMaxDelaySec = "60s";
          Environment =
            [
              "HOME=${config.home.homeDirectory}"
              "TERM=xterm-256color"
              # Include wrapped tools in PATH for child processes
              "PATH=${wrappedOpencode}/bin:${lib.makeBinPath (builtinPackages ++ cfg.packages)}:/run/current-system/sw/bin:/usr/bin:/bin"
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
        Install = {
          WantedBy = ["default.target"];
        };
      };
    })

    # macOS: launchd agent
    (mkIf pkgs.stdenv.isDarwin {
      launchd.agents.kimaki = {
        enable = true;
        config = {
          Label = "com.kimaki.discord-bot";
          ProgramArguments = kimakiCommand;
          WorkingDirectory = cfg.workingDirectory;
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/kimaki.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/kimaki.error.log";
          EnvironmentVariables =
            {
              HOME = config.home.homeDirectory;
              TERM = "xterm-256color";
              PATH = "${wrappedOpencode}/bin:${lib.makeBinPath (builtinPackages ++ cfg.packages)}:/usr/local/bin:/usr/bin:/bin";
              npm_config_cache = "${config.home.homeDirectory}/.npm";
            }
            // optionalAttrs (cfg.discordTokenSecret != null) {
              DISCORD_TOKEN_FILE = cfg.discordTokenSecret;
            }
            // optionalAttrs (cfg.geminiApiKeySecret != null) {
              GEMINI_API_KEY_FILE = cfg.geminiApiKeySecret;
            };
        };
      };
    })
  ]);
}
