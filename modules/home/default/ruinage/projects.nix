# Ruinage Project Processing
#
# This module handles:
# - Project option definitions (ruinous.ruinage.projects)
# - Auto-clone activation script
# - Project path resolution
#
# Projects are defined by their git repository. Having a project defined
# means it's enabled - no separate enable flag needed.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;
  ruinageLib = import ../../../../lib/ruinage/wrapper.nix {inherit lib pkgs;};

  # Budgey configuration submodule (reusable across assistants)
  budgeyType = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Include this assistant in the budgey registry.";
      };

      budgets = {
        weeklyUsd = mkOption {
          type = types.nullOr types.float;
          default = null;
          description = "Weekly budget limit in USD.";
          example = 50.0;
        };

        monthlyUsd = mkOption {
          type = types.nullOr types.float;
          default = null;
          description = "Monthly budget limit in USD.";
          example = 200.0;
        };
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Tags for categorizing this project.";
        example = ["core" "agents"];
      };

      # Path overrides for assistants that manage their own XDG dirs
      configDir = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override config directory for budgey registry (null = use computed path).";
        example = "/home/user/.config/kimaki";
      };

      stateDir = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override state directory for budgey registry (null = use computed path).";
        example = "/home/user/.local/state/kimaki";
      };

      dataDir = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override data directory for budgey registry (null = use computed path).";
        example = "/home/user/.local/share/kimaki";
      };
    };
  };

  # Project type definition - parameterized by homeDirectory
  mkProjectType = homeDirectory: types.submodule ({
    name,
    config,
    ...
  }: {
    options = {
      # Repository coordinates
      repo = mkOption {
        type = types.str;
        default = name;
        description = "Repository name. Defaults to the project key name.";
        example = "nix-config";
      };

      owner = mkOption {
        type = types.str;
        default = "iamruinous";
        description = "Repository owner/organization.";
      };

      forge = mkOption {
        type = types.str;
        default = "forge.meskill.farm";
        description = "Forge hostname (e.g., 'github.com', 'forge.meskill.farm').";
      };

      ref = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Git reference (branch, tag, or commit). Null for default branch.";
        example = "main";
      };

      # Working directory path
      workdir = mkOption {
        type = types.str;
        default = "${homeDirectory}/Projects/ruinage/${config.repo}";
        description = "Absolute path to the project working directory. Defaults to ~/Projects/ruinage/<repo>.";
        example = "/home/user/Projects/ruinage/nix-config";
      };

      # Environment configuration
      environmentFiles = mkOption {
        type = types.listOf types.path;
        default = [];
        description = "Additional environment files specific to this project.";
      };

      # Tmux session configuration
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

      # Direnv configuration
      direnv = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable direnv for this project.";
        };

        envrc = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Content of .envrc file (null to skip creation).";
        };
      };

      # Multi-assistant support
      assistants = {
        opencode = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable OpenCode assistant for this project.";
          };

          web = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable OpenCode web service.";
            };

            port = mkOption {
              type = types.nullOr types.port;
              default = null;
              description = "Port for OpenCode web server. Auto-assigned if null.";
            };

            fqdn = mkOption {
              type = types.str;
              default = "${name}.oc.ruinous.ai";
              description = "FQDN for Caddy reverse proxy. Defaults to <project-name>.oc.ruinous.ai.";
              example = "myproject.oc.ruinous.ai";
            };

            hostname = mkOption {
              type = types.str;
              default = "0.0.0.0";
              description = "Hostname/IP for OpenCode web service.";
            };

            logLevel = mkOption {
              type = types.enum ["DEBUG" "INFO" "WARN" "ERROR"];
              default = "ERROR";
              description = "Log level for OpenCode web service.";
            };

            mdns = mkOption {
              type = types.bool;
              default = false;
              description = "Enable mDNS for OpenCode service discovery.";
            };

            cors = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Additional CORS domains for OpenCode.";
            };

            printLogs = mkOption {
              type = types.bool;
              default = true;
              description = "Print OpenCode logs to stderr.";
            };
          };

          # Budgey cost tracking for OpenCode
          budgey = mkOption {
            type = budgeyType;
            default = {};
            description = "Budgey cost tracking configuration for OpenCode assistant.";
          };
        };

        kimaki = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Register this project with Kimaki Discord bot.";
          };

          direnvSnippet = mkOption {
            type = types.str;
            default = name;
            description = ''
              Name of the direnv snippet to source for this project.
              Defaults to the project name. Used to inject source line into .envrc.local.
            '';
            example = "nix";
          };

          # Budgey cost tracking for Kimaki (future use)
          budgey = mkOption {
            type = budgeyType;
            default = {};
            description = "Budgey cost tracking configuration for Kimaki assistant.";
          };
        };

        claude-code = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Claude Code assistant for this project.";
          };

          # Budgey cost tracking for Claude Code (future use)
          budgey = mkOption {
            type = budgeyType;
            default = {};
            description = "Budgey cost tracking configuration for Claude Code assistant.";
          };
        };

        gemini = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Gemini assistant for this project.";
          };

          # Budgey cost tracking for Gemini (future use)
          budgey = mkOption {
            type = budgeyType;
            default = {};
            description = "Budgey cost tracking configuration for Gemini assistant.";
          };
        };

        codex = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Codex assistant for this project.";
          };

          # Budgey cost tracking for Codex (future use)
          budgey = mkOption {
            type = budgeyType;
            default = {};
            description = "Budgey cost tracking configuration for Codex assistant.";
          };
        };
      };

    };
  });
in {
  options.ruinous.ruinage = {
    enable = mkEnableOption "Ruinage repository-first project management";

    projects = mkOption {
      type = types.attrsOf (mkProjectType config.home.homeDirectory);
      default = {};
      description = ''
        Repository-first project definitions.
        Each project is keyed by name and defines:
        - Repository coordinates (repo, owner, forge)
        - Assistant configurations (opencode, kimaki, etc.)

        Having a project defined means it's enabled - no separate enable flag needed.
        
        Defaults:
        - repo: project key name
        - owner: "iamruinous"
        - forge: "forge.meskill.farm"
        - workdir: ~/Projects/ruinage/<repo>
      '';
      example = literalExpression ''
        {
          nix-config = {
            repo = "nix-config";
            forge = "github.com";
            port = 9500;
            assistants.opencode = {
              enable = true;
              budgey.enable = true;
            };
          };
        }
      '';
    };

    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "Global environment files to include in all direnv snippets.";
    };

    direnv = {
      enable = mkEnableOption "Generate .envrc snippets for projects with environment files";

      autoInject = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Automatically inject source line into project .envrc.local files.
          When enabled, creates/updates .envrc.local in each project directory
          to source the corresponding direnv snippet from ~/.config/direnv/envrc.d/.
        '';
      };

      secretsDir = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/.local/state/agenix";
        description = "Directory where agenix secrets are decrypted (home-manager default).";
      };
    };
  };

  config = mkIf (cfg.enable or false) {
    # Auto-clone projects to workdir on activation
    home.activation.cloneRuinageProjects = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Ensure git can find ssh for cloning
      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh"
      ${concatMapStringsSep "\n" (projectName: let
        project = cfg.projects.${projectName};
      in ''
        # Project: ${projectName}
        PROJECT_PATH="${project.workdir}"
        if [ ! -d "$PROJECT_PATH" ]; then
          $VERBOSE_ECHO "ruinage: cloning ${projectName} to $PROJECT_PATH"
          mkdir -p "$(dirname "$PROJECT_PATH")"
          ${pkgs.git}/bin/git clone "${ruinageLib.mkGitUrl {
            owner = project.owner;
            repo = project.repo;
            forge = project.forge;
          }}" "$PROJECT_PATH" || echo "Warning: Failed to clone ${projectName}"
        else
          $VERBOSE_ECHO "ruinage: ${projectName} already exists at $PROJECT_PATH (skipping)"
        fi
      '') (attrNames cfg.projects)}
    '';
  };
}
