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
    openssh.tmux.attach.enable = true;
    openssh.remote.forwarding.enable = true;

    # Git config - use zenith-specific defaults for all repos
    git.default = {
      userEmail = "jade@ruinous.ai";
      signingKey = "/home/jmeskill/.ssh/id_codey_ed25519";
    };

    ai-cli = {
      opencode = {
        enable = true;
        # Disabled: notifier causing performance issues, needs debugging
        # notifier.enable = true;

        # Multiple config directories for independent sessions
        configs = {
          default = {
            notifier.enable = false;
          }; # ~/.config/opencode for interactive use

          web = {
            configDir = "${config.home.homeDirectory}/.config/opencode-web";
            notifier.enable = false;
          };

          kimaki = {
            configDir = "${config.home.homeDirectory}/.config/kimaki";
            notifier.enable = false;
          };
        };
      };
      opencode-web = {
        enable = true;
        projectPath = "/home/jmeskill/Projects/ruinous.ai/codey-agent-system";
        hostname = "172.17.0.1"; # Bind to docker interface
        configDir = "${config.home.homeDirectory}/.config/opencode-web";
        cacheDir = "${config.home.homeDirectory}/.cache/opencode-web";
        stateDir = "${config.home.homeDirectory}/.local/state/opencode-web";
        environmentFiles = [
          config.age.secrets.zenith_opencode_web_env.path
        ];
        # Declarative project registry for Recent Projects list
        projects = [
          "/home/jmeskill/Projects/ruinous.ai/codey-agent-system"
          "/home/jmeskill/Projects/ruinous.ai/dossiq-ai"
          "/home/jmeskill/Projects/ruinous.ai/ml-pspd"
          "/home/jmeskill/Projects/ruinous.ai/n8n-agent"
          "/home/jmeskill/Projects/ruinous.ai/n8n-messy-discord-bot"
          "/home/jmeskill/Projects/ruinous.ai/nix-config"
          "/home/jmeskill/Projects/kimaki/codey-agent-system"
          "/home/jmeskill/Projects/kimaki/dossiq-ai"
          "/home/jmeskill/Projects/kimaki/ml-pspd"
          "/home/jmeskill/Projects/kimaki/n8n-agent"
          "/home/jmeskill/Projects/kimaki/nix-config"
        ];
      };
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
