{
  flake,
  config,
  pkgs,
  lib,
  ...
}: let
  mcpConfigDir = ../../../../hosts/zenith/files/docker/mcp;
in {
  imports = [
    flake.homeModules.default
  ];

  home.file.".docker/cli-plugins/docker-mcp".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.docker-mcp-gateway}/bin/docker-mcp";

  home.activation.mcpConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.docker/mcp/catalogs"
    cp -f ${mcpConfigDir}/catalogs/farm-catalog.yaml "$HOME/.docker/mcp/catalogs/farm-catalog.yaml"
    cp -f ${mcpConfigDir}/config.yaml "$HOME/.docker/mcp/config.yaml"
    cp -f ${mcpConfigDir}/registry.yaml "$HOME/.docker/mcp/registry.yaml"
    cp -f ${mcpConfigDir}/tools.yaml "$HOME/.docker/mcp/tools.yaml"
  '';

  ruinous = {
    rust-motd.enable = true;
    loginHub.enable = true;
    openssh.remote.forwarding.enable = true;

    git.default = {
      userEmail = "jade@ruinous.ai";
      signingKey = "/home/jmeskill/.ssh/id_codey_ed25519";
    };

    # Hub session - always running, for general use
    tmuxp = {
      enable = true;
      sessions.hub = {
        windows = [
          {name = "shell"; focus = true;}
          {name = "docker"; command = "sudo lazydocker";}
        ];
      };
    };

    ai-cli = {
      opencode = {
        enable = true;
        configs.default.notifier.enable = false;
      };

      # Unified project-centric configuration
      # Generates tmuxp sessions + web services from same config
      opencode-projects = {
        enable = true;

        environmentFiles = [
          config.age.secrets.zenith_opencode_web_env.path
        ];

        projects = {
          # nix-config - CLI only (tmuxp session)
          nix = {
            workdir = "/home/jmeskill/Projects/github/iamruinous/nix-config";
            port = 9500;
          };

          # codey-agent-system - Web service (systemd)
          codey = {
            workdir = "/home/jmeskill/Projects/ruinous.ai/codey-agent-system";
            port = 9501;
            web = {
              enable = true;
              hostname = "172.17.0.1";
            };
          };

          # dossiq-ai
          dossiq = {
            workdir = "/home/jmeskill/Projects/ruinous.ai/dossiq-ai";
            port = 9502;
          };

          # ml-pspd
          ml-pspd = {
            workdir = "/home/jmeskill/Projects/ruinous.ai/ml-pspd";
            port = 9503;
          };

          # n8n-agent
          n8n-agent = {
            workdir = "/home/jmeskill/Projects/ruinous.ai/n8n-agent";
            port = 9504;
          };

          # n8n-messy-discord-bot
          messy-bot = {
            workdir = "/home/jmeskill/Projects/ruinous.ai/n8n-messy-discord-bot";
            port = 9505;
          };
        };
      };

      # Kimaki (separate identity) - keep as-is for now
      kimaki = {
        enable = true;
        configDir = "${config.home.homeDirectory}/.config/kimaki";
        cacheDir = "${config.home.homeDirectory}/.cache/kimaki";
        stateDir = "${config.home.homeDirectory}/.local/state/kimaki";
        environmentFiles = [
          config.age.secrets.zenith_opencode_web_env.path
          config.age.secrets.zenith_kimaki_env.path
        ];
      };
    };
  };

  age.secrets.zenith_opencode_web_env = {
    rekeyFile = ./files/opencode-web/env.age;
    mode = "400";
  };

  age.secrets.zenith_kimaki_env = {
    rekeyFile = ./files/kimaki/env.age;
    mode = "400";
  };

  home.stateVersion = "26.05";
}
