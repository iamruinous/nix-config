# ruinous.ai-cli.opencode-web.enable = true;
#
# Manages OpenCode Web UI services as persistent user daemons.
# Each service runs `opencode web` bound to a specific port for a project directory.
#
# Example:
#   ruinous.ai-cli.opencode-web = {
#     enable = true;
#     # Uses llm-agents opencode and common MCP tools by default
#     services = {
#       "nix-config" = {
#         projectPath = "/home/jmeskill/Projects/github/iamruinous/nix-config";
#         port = 18080;
#         # logLevel = "INFO";   # default
#         # mdns = true;         # default # printLogs = true;    # default
#         # cors = [];           # default
#       };
#     };
#   };
#
# This creates a systemd user service `opencode-web-nix-config.service` that can be
# attached to from other clients using `opencode attach http://<host>:18080`.
#
# ## Using agenix Environment Files (Linux only)
#
# You can pass encrypted environment files containing API keys and secrets to
# the opencode-web service using the `environmentFile` option. This uses systemd's
# EnvironmentFile directive to load variables at service startup.
#
# Example with agenix:
#
#   # In your home-configuration.nix or similar:
#   ruinous.ai-cli.opencode-web = {
#     enable = true;
#     services = {
#       "nix-config" = {
#         projectPath = "/home/jmeskill/Projects/nix-config";
#         port = 18080;
#         environmentFiles = [
#           config.age.secrets.opencode_common_env.path
#           config.age.secrets.opencode_web_nix_config.path
#         ];
#       };
#     };
#   };
#
#   # Declare the agenix secrets (in NixOS config or home-manager with agenix):
#   age.secrets.opencode_common_env = {
#     rekeyFile = ./files/opencode-web/common.env.age;
#     mode = "600";
#   };
#   age.secrets.opencode_web_nix_config = {
#     rekeyFile = ./files/opencode-web/nix-config.env.age;
#     mode = "600";
#   };
#
# Files are loaded in order, with later files overriding earlier ones.
#
# Note: environmentFiles is only supported on Linux (systemd). On macOS, an
# assertion will fail if you attempt to use this option.
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
  ];

  # Create a wrapped opencode with all necessary environment setup
  wrappedOpencode = pkgs.symlinkJoin {
    name = "opencode-wrapped";
    paths = [cfg.package];
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

  # Define the service submodule type
  serviceOpts = {name, ...}: {
    options = {
      projectPath = mkOption {
        type = types.str;
        description = "Absolute path to the project directory for this OpenCode instance.";
        example = "/home/user/Projects/my-project";
      };

      port = mkOption {
        type = types.port;
        description = "Port number for this OpenCode web server.";
        example = 18080;
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
        example = [];
      };

      environmentFiles = mkOption {
        type = types.listOf types.path;
        default = [];
        description = ''
          List of environment files to load into the service.
          Typically agenix secret paths like config.age.secrets.<name>.path.
          Variables in these files will be available to opencode and MCP servers.
          Files are loaded in order, with later files overriding earlier ones.

          Note: This option is only supported on Linux (systemd). On macOS (launchd),
          this option is ignored as launchd does not natively support EnvironmentFile.
        '';
        example = literalExpression ''
          [
            config.age.secrets.opencode_common_env.path
            config.age.secrets.opencode_web_nix_config.path
          ]
        '';
      };
    };
  };

  # Build command arguments for a service
  buildArgs = svc:
    [
      "${wrappedOpencode}/bin/opencode"
      "web"
      "--hostname"
      svc.hostname
      "--port"
      (toString svc.port)
      "--log-level"
      svc.logLevel
    ]
    ++ optionals svc.mdns ["--mdns"]
    ++ optionals svc.printLogs ["--print-logs"]
    ++ concatMap (domain: ["--cors" domain]) svc.cors
    ++ svc.extraArgs;
in {
  options.ruinous.ai-cli.opencode-web = {
    enable = mkEnableOption "OpenCode Web UI services";

    package = mkOption {
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

    services = mkOption {
      type = types.attrsOf (types.submodule serviceOpts);
      default = {};
      description = ''
        Attribute set of OpenCode web services to run.
        Each key becomes the service name suffix (e.g., "nix-config" -> "opencode-web-nix-config").
      '';
      example = literalExpression ''
        {
          "nix-config" = {
            projectPath = "/home/user/Projects/nix-config";
            port = 18080;
          };
          "another-project" = {
            projectPath = "/home/user/Projects/another";
            port = 18081;
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Assertions for macOS environmentFiles usage
    {
      assertions =
        lib.mapAttrsToList (name: svc: {
          assertion = !(pkgs.stdenv.isDarwin && svc.environmentFiles != []);
          message = ''
            opencode-web service "${name}" uses environmentFiles, but this is not supported on macOS.
            launchd does not have native EnvironmentFile support like systemd.
            Please set environment variables directly or use a wrapper script.
          '';
        })
        cfg.services;
    }

    # Linux: systemd user services
    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services = mapAttrs' (name: svc:
        nameValuePair "opencode-web-${name}" {
          Unit = {
            Description = "OpenCode Web UI for ${name}";
            After = ["network.target"] ++ optionals (svc.environmentFiles != []) ["agenix.service"];
            Requires = optionals (svc.environmentFiles != []) ["agenix.service"];
          };
          Service =
            {
              Type = "exec";
              WorkingDirectory = svc.projectPath;
              ExecStart = concatStringsSep " " (buildArgs svc);
              Restart = "always";
              RestartSec = "5s";
              RestartSteps = 5;
              RestartMaxDelaySec = "60s";
              Environment = [
                "HOME=${config.home.homeDirectory}"
                "TERM=xterm-256color"
                "PATH=${lib.makeBinPath (builtinPackages ++ cfg.packages)}:/run/current-system/sw/bin:/usr/bin:/bin"
                "NIX_LD=/run/current-system/sw/share/nix-ld/lib/ld.so"
                "NIX_LD_LIBRARY_PATH=${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]}:/run/current-system/sw/share/nix-ld/lib"
              ];
            }
            // optionalAttrs (svc.environmentFiles != []) {
              EnvironmentFile = svc.environmentFiles;
            };
          Install = {
            WantedBy = ["default.target"];
          };
        })
      cfg.services;
    })

    # macOS: launchd agents
    (mkIf pkgs.stdenv.isDarwin {
      launchd.agents = mapAttrs' (name: svc:
        nameValuePair "opencode-web-${name}" {
          enable = true;
          config = {
            Label = "com.opencode.web.${name}";
            ProgramArguments = buildArgs svc;
            WorkingDirectory = svc.projectPath;
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/opencode-web-${name}.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/opencode-web-${name}.error.log";
            EnvironmentVariables = {
              HOME = config.home.homeDirectory;
              TERM = "xterm-256color";
            };
          };
        })
      cfg.services;
    })
  ]);
}
