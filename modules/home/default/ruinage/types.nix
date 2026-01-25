# Ruinage Type Definitions
#
# This module defines shared types used across the ruinage system:
# - projectType: The core project submodule schema
# - assistantTypes: Per-assistant configuration submodules
# - namespaceType: Namespace (ruinage/kimaki) configuration
#
# Type definitions are placed here to avoid circular imports between modules.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  projectType = types.submodule ({
    name,
    config,
    ...
  }: {
    options = {
      # Repository coordinates
      repo = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Repository name (e.g., 'nix-config'). Null for local-only projects.";
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

      # Port configuration
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

      # Caddy reverse proxy configuration
      caddy = {
        fqdn = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            FQDN for Caddy reverse proxy (e.g., "myproject.oc.ruinous.ai").
            When set, automatically enables web service and configures CORS.
          '';
          example = "myproject.oc.ruinous.ai";
        };
      };

      # Web service configuration
      web = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Create a systemd user service for the web UI.
            Automatically enabled when caddy.fqdn is set.
          '';
        };

        hostname = mkOption {
          type = types.str;
          default = "0.0.0.0";
          description = "Hostname/IP to bind the web service to.";
        };

        logLevel = mkOption {
          type = types.enum ["DEBUG" "INFO" "WARN" "ERROR"];
          default = "ERROR";
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
          description = "Additional domains to allow for CORS (caddy.fqdn is automatically added).";
        };

        printLogs = mkOption {
          type = types.bool;
          default = true;
          description = "Print logs to stderr.";
        };
      };

      # Budgey cost tracking configuration
      budgey = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Include this project in the budgey-extractor registry.";
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

        # Path overrides for external projects (like kimaki) that manage their own XDG dirs
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

      # Namespace configuration (multi-namespace support)
      namespaces = {
        ruinage = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable this project in the ruinage namespace.";
          };
        };

        kimaki = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable this project in the kimaki namespace.";
          };
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

          port = mkOption {
            type = types.nullOr types.port;
            default = null;
            description = "Port for OpenCode server (overrides top-level port if set).";
          };

          hostname = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Hostname/IP for OpenCode server.";
          };

          caddy = {
            fqdn = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "FQDN for OpenCode Caddy reverse proxy.";
              example = "myproject.oc.ruinous.ai";
            };
          };

          web = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable OpenCode web service.";
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
              default = true;
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
        };

        claude-code = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Claude Code assistant for this project.";
          };
        };

        gemini = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Gemini assistant for this project.";
          };
        };

        codex = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Codex assistant for this project.";
          };
        };
      };

      # Documentation configuration
      docs = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable documentation aggregation for this project.";
        };

        flakeInput = mkOption {
          type = types.str;
          default = name;
          description = "Flake input name to get docs from (e.g., 'ruinagents' for flake.inputs.ruinagents).";
          example = "ruinagents";
        };

        packageOutput = mkOption {
          type = types.str;
          default = "docs";
          description = "Package output name within the flake input (e.g., 'docs' for .packages.\${system}.docs).";
          example = "docs";
        };

        title = mkOption {
          type = types.str;
          default = name;
          description = "Documentation title.";
        };
      };
    };
  });
in
{}
