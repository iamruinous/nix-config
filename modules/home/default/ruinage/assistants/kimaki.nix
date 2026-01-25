# Ruinage Kimaki Assistant Integration
#
# This module provides:
# - Global Kimaki settings (ruinous.ruinage.assistants.kimaki.*)
# - Service configuration (stateDir, configDir, environmentFiles, etc.)
# - Per-project Kimaki registration
#
# Kimaki is a Discord bot for controlling OpenCode agents, connecting
# Discord channels to OpenCode projects for interaction via messages and voice.
#
# FIRST-TIME SETUP (required before enabling the service):
#   1. Run `npx -y kimaki@latest` manually in a terminal
#   2. Follow the interactive setup wizard to configure Discord bot
#   3. Credentials are stored in ~/.kimaki/discord-sessions.db
#   4. After setup, enable the service for persistent operation
#
# Example:
#   ruinous.ruinage = {
#     enable = true;
#
#     # Global kimaki configuration
#     assistants.kimaki = {
#       enable = true;
#       stateDir = "${config.home.homeDirectory}/.local/state/kimaki";
#       configDir = "${config.home.homeDirectory}/.config/kimaki";
#       environmentFiles = [ config.age.secrets.kimaki_env.path ];
#     };
#
#     # Project-level kimaki registration
#     projects.my-project = {
#       repo = "my-project";
#       namespaces.ruinage.enable = true;
#       assistants.kimaki.enable = true;  # Register with kimaki
#       assistants.kimaki.direnvSnippet = "my-project";  # Optional direnv
#     };
#   };
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
  cfg = config.ruinous.ruinage.assistants.kimaki;
  ruinageCfg = config.ruinous.ruinage;
  llmAgentsPkgs = flake.inputs.llm-agents.packages.${pkgs.system};

  # Import shared Ruinage library from top-level lib/
  ruinageLib = import ../../../../../lib/ruinage/wrapper.nix {inherit lib pkgs;};

  # Create a wrapped opencode with all necessary environment setup
  wrappedOpencode = ruinageLib.mkWrappedOpencode {
    package = cfg.opencodePackage;
  };

  # Build the command to run kimaki via npx
  kimakiCommand =
    [
      "${pkgs.nodejs}/bin/npx"
      "-y"
      "kimaki@latest"
    ]
    ++ cfg.extraArgs;

  # Filter projects with assistants.kimaki.enable = true
  kimakiProjects = filterAttrs (name: project:
    project.assistants.kimaki.enable or false
  ) (ruinageCfg.projects or {});

  # Compute workdir for a project: ~/Projects/kimaki/<project_name>
  mkKimakiWorkdir = name: "${config.home.homeDirectory}/Projects/kimaki/${name}";
in {
  options.ruinous.ruinage.assistants.kimaki = {
    enable = mkEnableOption "Kimaki Discord bot for OpenCode control";

    opencodePackage = mkOption {
      type = types.package;
      default = llmAgentsPkgs.opencode;
      description = "The opencode package to use.";
      example = literalExpression "pkgs.opencode";
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
        - <stateDir>/opencode/auth.json -> ~/.local/share/opencode/auth.json
        - <stateDir>/opencode/mcp-auth.json -> ~/.local/share/opencode/mcp-auth.json
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
    };

    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [];
      description = ''
        List of environment files to load into the service.
        Typically agenix secret paths like config.age.secrets.<name>.path.
        Variables in these files will be available to kimaki and child processes.
        Files are loaded in order, with later files overriding earlier ones.
      '';
      example = literalExpression ''
        [
          config.age.secrets.opencode_common_env.path
          config.age.secrets.kimaki_env.path
        ]
      '';
    };

    direnv = {
      autoInject = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically inject direnv source lines into project .envrc.local files.";
      };

      snippetsDir = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/.config/direnv/envrc.d";
        description = "Directory containing direnv snippets.";
      };
    };
  };

  config = mkIf ((ruinageCfg.enable or false) && cfg.enable) (mkMerge [
    # Ensure kimaki data directory exists and symlink opencode binary
    {
      home.file.".kimaki/.keep".text = "";
      home.file.".opencode/bin/opencode".source = "${wrappedOpencode}/bin/opencode";
    }

    # Assertion for linux-only usage
    {
      assertions = [
        {
          assertion = pkgs.stdenv.isLinux;
          message = "kimaki is linux-only (systemd user service).";
        }
      ];
    }

    # Symlink shared auth files when using isolated dataDir
    (mkIf (cfg.dataDir != null) {
      home.file = ruinageLib.mkAuthSymlinks {
        dataDir = cfg.dataDir;
        homeDirectory = config.home.homeDirectory;
        mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
      };
    })

    # Auto-clone kimaki projects to ~/Projects/kimaki/<name>
    # Kimaki uses separate clones from ruinage to prevent workspace conflicts
    (mkIf (kimakiProjects != {}) {
      home.activation.cloneKimakiProjects = lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Ensure git can find ssh for cloning
        export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh"
        ${concatMapStringsSep "\n" (name: let
          project = kimakiProjects.${name};
          workdir = mkKimakiWorkdir name;
        in ''
          # Project: ${name}
          if [ ! -d "${workdir}" ]; then
            $VERBOSE_ECHO "kimaki: cloning ${name} to ${workdir}"
            mkdir -p "$(dirname "${workdir}")"
            ${pkgs.git}/bin/git clone "${ruinageLib.mkGitUrl {
              owner = project.owner;
              repo = project.repo;
              forge = project.forge;
            }}" "${workdir}" || echo "Warning: Failed to clone ${name} for kimaki"
          else
            $VERBOSE_ECHO "kimaki: ${name} already exists at ${workdir} (skipping)"
          fi
        '') (attrNames kimakiProjects)}
      '';
    })

    # Register projects with kimaki (projects with assistants.kimaki.enable = true)
    # Runs after cloneKimakiProjects to ensure directories exist
    # Checks if already registered to avoid unnecessary API calls and rate limits
    (mkIf (kimakiProjects != {}) {
      home.activation.registerKimakiProjects = lib.hm.dag.entryAfter ["writeBoundary" "cloneKimakiProjects"] ''
        KIMAKI_DB="${config.home.homeDirectory}/.kimaki/discord-sessions.db"

        # Helper function to check if project is already registered
        is_project_registered() {
          local workdir="$1"
          if [ -f "$KIMAKI_DB" ]; then
            # Check if workdir exists in channel_directories table
            ${pkgs.sqlite}/bin/sqlite3 "$KIMAKI_DB" \
              "SELECT COUNT(*) FROM channel_directories WHERE directory = '$workdir';" 2>/dev/null | \
              ${pkgs.gnugrep}/bin/grep -q '^[1-9]'
          else
            return 1
          fi
        }

        ${concatMapStringsSep "\n" (name: let
          workdir = mkKimakiWorkdir name;
        in ''
          if [ -d "${workdir}" ]; then
            if is_project_registered "${workdir}"; then
              $VERBOSE_ECHO "kimaki: ${name} already registered at ${workdir} (skipping)"
            else
              $VERBOSE_ECHO "kimaki: registering project ${name} at ${workdir}"
              if ! ${pkgs.nodejs}/bin/npx -y kimaki@latest add-project "${workdir}" 2>&1; then
                echo "Warning: Failed to register ${name} with kimaki. Run manually: npx -y kimaki@latest add-project \"${workdir}\""
              fi
            fi
          else
            $VERBOSE_ECHO "kimaki: project directory ${workdir} does not exist, skipping registration"
          fi
        '') (attrNames kimakiProjects)}
      '';
    })

    # Auto-inject direnv snippets into .envrc.local
    (mkIf (kimakiProjects != {} && cfg.direnv.autoInject) {
      home.activation.injectKimakiDirenvSnippets = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${concatMapStringsSep "\n" (name: let
          project = kimakiProjects.${name};
          workdir = mkKimakiWorkdir name;
          snippetName = project.assistants.kimaki.direnvSnippet;
          snippetPath = "${cfg.direnv.snippetsDir}/${snippetName}.sh";
          envrcLocal = "${workdir}/.envrc.local";
          sourceLine = "source_env ${snippetPath}";
          markerComment = "# kimaki: auto-injected";
        in optionalString (snippetName != null) ''
          if [ -d "${workdir}" ] && [ -f "${snippetPath}" ]; then
            if [ -f "${envrcLocal}" ]; then
              if ! ${pkgs.gnugrep}/bin/grep -qF "${sourceLine}" "${envrcLocal}"; then
                $VERBOSE_ECHO "kimaki: injecting direnv snippet into ${name}/.envrc.local"
                echo "" >> "${envrcLocal}"
                echo "${markerComment}" >> "${envrcLocal}"
                echo "${sourceLine}" >> "${envrcLocal}"
              fi
            else
              $VERBOSE_ECHO "kimaki: creating ${name}/.envrc.local with direnv snippet"
              echo "${markerComment}" > "${envrcLocal}"
              echo "${sourceLine}" >> "${envrcLocal}"
            fi
          fi
        '') (attrNames kimakiProjects)}
      '';
    })

    # Linux: systemd user service
    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.kimaki = {
        Unit = {
          Description = "Kimaki Discord bot for OpenCode control";
          After = ["network.target"] ++ optionals (cfg.environmentFiles != []) ["agenix.service"];
          Wants = optionals (cfg.environmentFiles != []) ["agenix.service"];
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
            # System and user profile paths provide all installed packages
            Environment = ruinageLib.mkSystemdEnvironment {
              homeDirectory = config.home.homeDirectory;
              configDir = cfg.configDir;
              cacheDir = cfg.cacheDir;
              stateDir = cfg.stateDir;
              dataDir = cfg.dataDir;
              prependPaths = ["${wrappedOpencode}/bin"];
              extraEnv =
                [
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
