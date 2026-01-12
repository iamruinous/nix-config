{
  flake,
  config,
  pkgs,
  lib,
  ...
}: let
  mcpConfigDir = ../../../../hosts/pilaster/files/docker/mcp;
in {
  imports = [
    flake.homeModules.default
  ];

  ruinous.rust-motd.enable = true;
  ruinous.loginHub.enable = true;

  home.file.".docker/cli-plugins/docker-mcp".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.docker-mcp-gateway}/bin/docker-mcp";

  # MCP Gateway configuration files - copied as real files (not symlinks) for Docker access
  # Docker containers can't follow symlinks to paths outside their mounted volumes
  home.activation.mcpConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.docker/mcp/catalogs"
    cp -f ${mcpConfigDir}/catalogs/farm-catalog.yaml "$HOME/.docker/mcp/catalogs/farm-catalog.yaml"
    cp -f ${mcpConfigDir}/config.yaml "$HOME/.docker/mcp/config.yaml"
    cp -f ${mcpConfigDir}/registry.yaml "$HOME/.docker/mcp/registry.yaml"
    cp -f ${mcpConfigDir}/tools.yaml "$HOME/.docker/mcp/tools.yaml"
  '';

  home.stateVersion = "26.05";
}
