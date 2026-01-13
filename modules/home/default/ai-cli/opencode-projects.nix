# ruinous.ai-cli.opencode-projects.enable = true;
#
# Unified project-centric OpenCode configuration.
# Defines projects once, generates both tmuxp sessions AND web services.
# CLI and web share the same state/config directories per project.
#
# Example:
#   ruinous.ai-cli.opencode-projects = {
#     enable = true;
#
#     # Environment files applied to ALL projects
#     environmentFiles = [
#       config.age.secrets.opencode_common_env.path
#     ];
#
#     projects = {
#       nix-config = {
#         workdir = "/home/jmeskill/Projects/github/iamruinous/nix-config";
#         port = 9500;
#       };
#
#       codey = {
#         workdir = "/home/jmeskill/Projects/ruinous.ai/codey-agent-system";
#         port = 9501;
#         web.enable = true;
#         web.hostname = "172.17.0.1";
#       };
#     };
#   };
#
# This creates:
#   - Per-project state: ~/.local/state/opencode-<project>/
#   - Per-project config: ~/.config/opencode-<project>/
#   - Per-project cache: ~/.cache/opencode-<project>/
#   - tmuxp sessions: tmuxp load <project>
#   - Web services: opencode-<project>.service (if web.enable = true)
#
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ai-cli.opencode-projects;
  llmAgentsPkgs = flake.inputs.llm-agents.packages.${pkgs.system};
  opcodeLib = import ../../../../lib/opencode/wrapper.nix {inherit lib pkgs;};

  # Project submodule - no references to cfg in defaults
  projectType = types.submodule ({name, config, ...}: {
    options = {
      workdir = mkOption {
        type = types.str;
        description = "Absolute path to the project directory.";
        example = "/home/user/Projects/my-project";
      };

      port = mkOption {
        type = types.port;
        description = "Port number for the OpenCode server.";
        example = 9500;
      };

      hostname = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Hostname/IP to bind to for CLI serve mode.";
      };

      environmentFiles = mkOption {
        type = types.listOf types.path;
        default = [];
        description = "Additional environment files specific to this project.";
      };

      tmuxp = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Generate a tmuxp session for this project.";
        };

        extraWindows = mkOption {
          type = types.listOf (types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Window name.";
              };
              command = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Command to run (null for blank shell).";
              };
              focus = mkOption {
                type = types.bool;
                default = false;
                description = "Focus this window.";
              };
            };
          });
          default = [];
          description = "Additional windows to add to the tmuxp session.";
        };
      };

      web = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Create a systemd user service for the web UI.";
        };

        hostname = mkOption {
          type = types.str;
          default = "0.0.0.0";
          description = "Hostname/IP to bind the web service to.";
        };

        logLevel = mkOption {
          type = types.enum ["DEBUG" "INFO" "WARN" "ERROR"];
          default = "WARN";
          description = "Log level for the web service.";
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
        };

        printLogs = mkOption {
          type = types.bool;
          default = true;
          description = "Print logs to stderr.";
        };
      };
    };
  });

  # Helper to compute paths for a project
  mkProjectPaths = projectName: {
    config = "${cfg.configBaseDir}/opencode-${projectName}";
    state = "${cfg.stateBaseDir}/opencode-${projectName}";
    cache = "${cfg.cacheBaseDir}/opencode-${projectName}";
    data = "${cfg.dataBaseDir}/opencode-${projectName}";
  };

  # Create wrapped opencode for services
  wrappedOpencode = opcodeLib.mkWrappedOpencode {
    package = cfg.package;
    extraPackages = cfg.packages;
  };

  # Generate tmuxp session for a project
  mkTmuxpSession = name: project: {
    startDirectory = project.workdir;
    startCommands = ["direnv exec . true"];

    windows =
      [
        {
          name = "server";
          command = "opencode serve --print-logs --hostname ${project.hostname} --port ${toString project.port}";
        }
        {
          name = "opencode";
          command = "sleep 2 && opencode attach http://localhost:${toString project.port}";
          focus = true;
        }
        {
          name = "editor";
          command = "nvim .";
        }
        {name = "shell";}
      ]
      ++ project.tmuxp.extraWindows;
  };

  # Generate systemd service for a project
  mkWebService = name: project: let
    paths = mkProjectPaths name;
    buildArgs = [
      "${wrappedOpencode}/bin/opencode"
      "web"
      "--hostname"
      project.web.hostname
      "--port"
      (toString project.port)
      "--log-level"
      project.web.logLevel
    ]
    ++ optionals project.web.mdns ["--mdns"]
    ++ optionals project.web.printLogs ["--print-logs"]
    ++ concatMap (domain: ["--cors" domain]) project.web.cors;

    allEnvFiles = cfg.environmentFiles ++ project.environmentFiles;
  in {
    Unit = {
      Description = "OpenCode Web UI - ${name}";
      After = ["network.target"] ++ optionals (allEnvFiles != []) ["agenix.service"];
      Requires = optionals (allEnvFiles != []) ["agenix.service"];
    };
    Service = {
      Type = "exec";
      WorkingDirectory = project.workdir;
      ExecStart = concatStringsSep " " buildArgs;
      Restart = "always";
      RestartSec = "5s";
      RestartSteps = 5;
      RestartMaxDelaySec = "60s";
      Environment = opcodeLib.mkSystemdEnvironment {
        homeDirectory = config.home.homeDirectory;
        extraPackages = cfg.packages;
        configDir = paths.config;
        cacheDir = paths.cache;
        stateDir = paths.state;
        dataDir = paths.data;
        includeSystemPath = true;
      };
    } // optionalAttrs (allEnvFiles != []) {
      EnvironmentFile = allEnvFiles;
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  # Generate opencode config entry for a project
  mkOpencodeConfig = name: project: let
    paths = mkProjectPaths name;
  in {
    configDir = paths.config;
    notifier.enable = false;
  };

  # Projects with tmuxp enabled
  tmuxpProjects = filterAttrs (_: p: p.tmuxp.enable) cfg.projects;

  # Projects with web service enabled
  webProjects = filterAttrs (_: p: p.web.enable) cfg.projects;

in {
  options.ruinous.ai-cli.opencode-projects = {
    enable = mkEnableOption "Unified OpenCode project configuration";

    package = mkOption {
      type = types.package;
      default = llmAgentsPkgs.opencode;
      description = "The opencode package to use.";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = opcodeLib.defaultPackages;
      description = "Additional packages to include in PATH for OpenCode services.";
    };

    stateBaseDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/state";
      description = "Base directory for per-project state.";
    };

    configBaseDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.config";
      description = "Base directory for per-project config.";
    };

    cacheBaseDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.cache";
      description = "Base directory for per-project cache.";
    };

    dataBaseDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share";
      description = "Base directory for per-project data.";
    };

    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "Environment files applied to ALL projects.";
    };

    projects = mkOption {
      type = types.attrsOf projectType;
      default = {};
      description = "Project definitions.";
      example = literalExpression ''
        {
          nix-config = {
            workdir = "/home/user/Projects/nix-config";
            port = 9500;
          };
          my-app = {
            workdir = "/home/user/Projects/my-app";
            port = 9501;
            web.enable = true;
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = pkgs.stdenv.isLinux || (all (_: p: !p.web.enable) (attrValues cfg.projects));
          message = "OpenCode web services are Linux-only (require systemd).";
        }
      ];
    }

    # Generate opencode config entries for all projects
    {
      ruinous.ai-cli.opencode.configs = mapAttrs mkOpencodeConfig cfg.projects;
    }

    # Generate tmuxp sessions
    (mkIf (tmuxpProjects != {}) {
      ruinous.tmuxp.sessions = mapAttrs mkTmuxpSession tmuxpProjects;
    })

    # Generate web services (Linux only)
    (mkIf (pkgs.stdenv.isLinux && webProjects != {}) {
      systemd.user.services = mapAttrs' (name: project:
        nameValuePair "opencode-${name}" (mkWebService name project)
      ) webProjects;
    })

    # Create auth symlinks for isolated state directories
    (mkIf (webProjects != {}) {
      home.file = mkMerge (mapAttrsToList (name: project: let
        paths = mkProjectPaths name;
      in
        opcodeLib.mkAuthSymlinks {
          stateDir = paths.state;
          homeDirectory = config.home.homeDirectory;
          mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
        }
      ) webProjects);
    })

    # Sync project registries during activation
    {
      home.activation.syncOpencodeProjectRegistries = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${concatMapStringsSep "\n" (name: let
          project = cfg.projects.${name};
          paths = mkProjectPaths name;
          storageDir = "${paths.data}/opencode/storage/project";
          id = builtins.hashString "sha1" project.workdir;
          jsonFile = "${storageDir}/${id}.json";
        in ''
          # Project: ${name} (${project.workdir})
          mkdir -p "${storageDir}"
          TIMESTAMP=$(date +%s)000

          if [ ! -f "${jsonFile}" ]; then
            $VERBOSE_ECHO "opencode-projects: registering ${name}: ${project.workdir}"
            cat > "${jsonFile}" << 'PROJECTEOF'
          {
            "id": "${id}",
            "worktree": "${project.workdir}",
            "vcs": "git",
            "time": {
              "created": TIMESTAMP_PLACEHOLDER,
              "updated": TIMESTAMP_PLACEHOLDER
            },
            "sandboxes": []
          }
          PROJECTEOF
            ${pkgs.gnused}/bin/sed -i "s/TIMESTAMP_PLACEHOLDER/$TIMESTAMP/g" "${jsonFile}"
          fi
        '') (attrNames cfg.projects)}
      '';
    }
  ]);
}
