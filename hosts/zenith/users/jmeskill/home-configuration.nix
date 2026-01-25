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
          {
            name = "top";
            command = "btop";
          }
          {
            name = "docker";
            command = "sudo lazydocker";
          }
          {
            name = "shell";
            focus = true;
          }
        ];
      };
    };

    # ai-cli = {
    #   opencode = {
    #     enable = true;
    #     configs.default.notifier.enable = false;
    #   };
    #
    #   # OpenCode projects moved to chassis - web services run there with native Caddy
    #   # Kimaki moved to chassis
    # };
  };

  home.stateVersion = "26.05";
}
