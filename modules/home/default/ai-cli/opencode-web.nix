# ruinous.ai-cli.opencode-web.enable = true;
#
# Manages OpenCode Web UI services as persistent user daemons.
# Each service runs `opencode web` bound to a specific port for a project directory.
#
# Example:
#   ruinous.ai-cli.opencode-web = {
#     enable = true;
#     packages = with pkgs; [uv pnpm nodejs];  # Tools for MCP servers
#     services = {
#       "nix-config" = {
#         projectPath = "/home/jmeskill/Projects/github/iamruinous/nix-config";
#         port = 18080;
#         # logLevel = "INFO";   # default
#         # mdns = true;         # default
#         # printLogs = true;    # default
#         # cors = [];           # default
#       };
#     };
#   };
#
# This creates a systemd user service `opencode-web-nix-config.service` that can be
# attached to from other clients using `opencode attach http://<host>:18080`.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ai-cli.opencode-web;

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
        default = "INFO";
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
      default = pkgs.opencode;
      description = "The opencode package to use.";
      example = literalExpression "flake.inputs.llm-agents.packages.\${pkgs.system}.opencode";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = ''
        Additional packages to include in the service PATH.
        Useful for MCP servers that need tools like uvx, pnpm, etc.
      '';
      example = literalExpression "[pkgs.uv pkgs.pnpm pkgs.nodejs]";
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
    # Linux: systemd user services
    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services = mapAttrs' (name: svc:
        nameValuePair "opencode-web-${name}" {
          Unit = {
            Description = "OpenCode Web UI for ${name}";
            After = ["network.target"];
          };
          Service = {
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
              # Include wrapped tools (git, openssh, user packages) in PATH for child processes
              "PATH=${lib.makeBinPath (builtinPackages ++ cfg.packages)}:/run/current-system/sw/bin:/usr/bin:/bin"
            ];
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
