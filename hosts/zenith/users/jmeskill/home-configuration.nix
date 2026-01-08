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
        notifier.enable = true;
      };
      opencode-web = {
        enable = true;
        services = {
          "nix-config" = {
            projectPath = "/home/jmeskill/Projects/ruinous.ai/nix-config";
            port = 18080;
            cors = ["zenith.meskill.farm"];
            environmentFiles = [config.age.secrets.zenith_opencode_web_nix_env.path];
          };
          "n8n-agent" = {
            projectPath = "/home/jmeskill/Projects/ruinous.ai/n8n-agent";
            port = 18081;
            cors = ["zenith.meskill.farm"];
            environmentFiles = [
              config.age.secrets.zenith_opencode_web_shared_env.path
              config.age.secrets.zenith_opencode_web_n8n_env.path
            ];
          };
          "dossiq-ai" = {
            projectPath = "/home/jmeskill/Projects/ruinous.ai/dossiq-ai";
            port = 18082;
            cors = ["zenith.meskill.farm"];
            environmentFiles = [
              config.age.secrets.zenith_opencode_web_shared_env.path
              config.age.secrets.zenith_opencode_web_dossiq_env.path
            ];
          };
          "codey-agent-system" = {
            projectPath = "/home/jmeskill/Projects/ruinous.ai/codey-agent-system";
            port = 18083;
            cors = ["zenith.meskill.farm"];
            environmentFiles = [
              config.age.secrets.zenith_opencode_web_shared_env.path
              config.age.secrets.zenith_opencode_web_codey_env.path
            ];
          };
        };
      };
      kimaki = {
        enable = true;
        environmentFiles = [
          config.age.secrets.zenith_opencode_web_shared_env.path
          config.age.secrets.zenith_kimaki_env.path
        ];
      };
    };
  };

  age.secrets.zenith_opencode_web_shared_env = {
    rekeyFile = ./files/opencode-web/shared.env.age;
    mode = "400";
  };

  age.secrets.zenith_opencode_web_nix_env = {
    rekeyFile = ./files/opencode-web/nix.env.age;
    mode = "400";
  };

  age.secrets.zenith_opencode_web_n8n_env = {
    rekeyFile = ./files/opencode-web/n8n.env.age;
    mode = "400";
  };

  age.secrets.zenith_opencode_web_dossiq_env = {
    rekeyFile = ./files/opencode-web/dossiq.env.age;
    mode = "400";
  };

  age.secrets.zenith_opencode_web_codey_env = {
    rekeyFile = ./files/opencode-web/codey.env.age;
    mode = "400";
  };

  age.secrets.zenith_kimaki_env = {
    rekeyFile = ./files/kimaki/env.age;
    mode = "400";
  };

  home.stateVersion = "26.05";
}
