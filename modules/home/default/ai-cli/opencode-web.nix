# ruinous.ai-cli.opencode-web.enable = true;
#
# Manages a single OpenCode Web UI service as a persistent user daemon.
# Runs `opencode web` bound to a specific port for a project directory.
#
# Example:
#   ruinous.ai-cli.opencode-web = {
#     enable = true;
#     projectPath = "/home/jmeskill/Projects/github/iamruinous/nix-config";
#     port = 18080;
#     configDir = "${config.home.homeDirectory}/.config/opencode-web";
#     cacheDir = "${config.home.homeDirectory}/.cache/opencode-web";
#     stateDir = "${config.home.homeDirectory}/.local/state/opencode-web";
#   };
#
# This creates a systemd user service `opencode-web.service` that can be
# attached to from other clients using `opencode attach http://<host>:18080`.
#
# ## Using agenix Environment Files (Linux only)
#
# You can pass encrypted environment files containing API keys and secrets to
# the opencode-web service using the `environmentFiles` option. This uses systemd's
# EnvironmentFile directive to load variables at service startup.
#
# Example with agenix:
#
#   ruinous.ai-cli.opencode-web = {
#     enable = true;
#     projectPath = "/home/jmeskill/Projects/nix-config";
#     port = 18080;
#     environmentFiles = [
#       config.age.secrets.opencode_env.path
#     ];
#   };
#
# Note: opencode-web is linux-only and requires systemd.
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ai-cli.opencode-web;
  llmAgentsPkgs = flake.inputs.llm-agents.packages.${pkgs.system};

  # Import shared OpenCode library from top-level lib/
  opcodeLib = import ../../../../lib/opencode/wrapper.nix {inherit lib pkgs;};

  # Create a wrapped opencode with all necessary environment setup
  wrappedOpencode = opcodeLib.mkWrappedOpencode {
    package = cfg.package;
    extraPackages = cfg.packages;
  };

  # Build command arguments
  buildArgs =
    [
      "${wrappedOpencode}/bin/opencode"
      "web"
      "--hostname"
      cfg.hostname
      "--port"
      (toString cfg.port)
      "--log-level"
      cfg.logLevel
    ]
    ++ optionals cfg.mdns ["--mdns"]
    ++ optionals cfg.printLogs ["--print-logs"]
    ++ concatMap (domain: ["--cors" domain]) cfg.cors
    ++ cfg.extraArgs;
in {
  options.ruinous.ai-cli.opencode-web = {
    enable = mkEnableOption "OpenCode Web UI service";

    package = mkOption {
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

    projectPath = mkOption {
      type = types.str;
      description = "Absolute path to the project directory for the OpenCode instance.";
      example = "/home/user/Projects/my-project";
    };

    port = mkOption {
      type = types.port;
      default = 18080;
      description = "Port number for the OpenCode web server.";
    };

    hostname = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Hostname/IP to bind to. Use 0.0.0.0 for all interfaces.";
    };

    logLevel = mkOption {
      type = types.enum ["DEBUG" "INFO" "WARN" "ERROR"];
      default = "WARN";
      description = "Log level for the OpenCode server.";
    };

    mdns = mkOption {
      type = types.bool;
      default = true;
      description = "Enable mDNS service discovery.";
    };

    cors = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional domains to allow for CORS.";
      example = ["https://example.com"];
    };

    printLogs = mkOption {
      type = types.bool;
      default = true;
      description = "Print logs to stderr.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra arguments to pass to opencode web.";
    };

    configDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Custom config directory for the opencode-web service.
        When set, OPENCODE_CONFIG_DIR environment variable is set to this path,
        keeping service sessions independent from interactive opencode usage.
      '';
      example = "/home/user/.config/opencode-web";
    };

    cacheDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Custom cache directory for the opencode-web service.
        When set, XDG_CACHE_HOME environment variable is set to this path,
        keeping service cache independent from interactive opencode usage.
      '';
      example = "/home/user/.cache/opencode-web";
    };

    stateDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Custom state directory for the opencode-web service.
        When set, XDG_STATE_HOME environment variable is set to this path,
        keeping service state (logs, history) independent from interactive opencode usage.

        Authentication tokens are shared with interactive opencode via symlinks:
        - <stateDir>/opencode/auth.json -> ~/.local/state/opencode/auth.json
        - <stateDir>/opencode/mcp-auth.json -> ~/.local/state/opencode/mcp-auth.json
      '';
      example = "/home/user/.local/state/opencode-web";
    };

    dataDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Custom data directory for the opencode-web service.
        When set, XDG_DATA_HOME environment variable is set to this path,
        keeping service data (project registry) independent from interactive opencode usage.

        OpenCode stores registered projects in $XDG_DATA_HOME/opencode/storage/project/.
        When isolated, the service starts with an empty project registry and auto-registers
        the projectPath on first run.
      '';
      example = "/home/user/.local/share/opencode-web";
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

    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [];
      description = ''
        List of environment files to load into the service.
        Typically agenix secret paths like config.age.secrets.<name>.path.
        Variables in these files will be available to opencode and MCP servers.
        Files are loaded in order, with later files overriding earlier ones.

        Note: opencode-web is linux-only and requires systemd.
      '';
      example = literalExpression ''
        [
          config.age.secrets.opencode_env.path
        ]
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Assertion for linux-only usage
    {
      assertions = [
        {
          assertion = pkgs.stdenv.isLinux;
          message = ''
            opencode-web is linux-only (systemd user service).
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
      systemd.user.services.opencode-web = {
        Unit = {
          Description = "OpenCode Web UI";
          After = ["network.target"] ++ optionals (cfg.environmentFiles != []) ["agenix.service"];
          Requires = optionals (cfg.environmentFiles != []) ["agenix.service"];
        };
        Service =
          {
            Type = "exec";
            WorkingDirectory = cfg.projectPath;
            ExecStart = concatStringsSep " " buildArgs;
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
