{
  flake,
  config,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.default
  ];

  ruinous.openssh.tmux.attach.enable = true;

  home.file.".docker/cli-plugins/docker-mcp".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.docker-mcp-gateway}/bin/docker-mcp";

  # MCP Gateway configuration files (copied, not symlinked, for Docker access)
  home.file.".docker/mcp/catalogs/farm-catalog.yaml".source = ../../../../hosts/pilaster/files/docker/mcp/catalogs/farm-catalog.yaml;
  home.file.".docker/mcp/config.yaml".source = ../../../../hosts/pilaster/files/docker/mcp/config.yaml;
  home.file.".docker/mcp/registry.yaml".source = ../../../../hosts/pilaster/files/docker/mcp/registry.yaml;
  home.file.".docker/mcp/tools.yaml".source = ../../../../hosts/pilaster/files/docker/mcp/tools.yaml;

  home.stateVersion = "26.05";
}
