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

  # MCP Gateway configuration files (managed from nix-config repo)
  home.file.".docker/mcp/catalogs/farm-catalog.yaml".source = config.lib.file.mkOutOfStoreSymlink "/home/jmeskill/Projects/github/iamruinous/nix-config/hosts/pilaster/files/docker/mcp/catalogs/farm-catalog.yaml";
  home.file.".docker/mcp/config.yaml".source = config.lib.file.mkOutOfStoreSymlink "/home/jmeskill/Projects/github/iamruinous/nix-config/hosts/pilaster/files/docker/mcp/config.yaml";
  home.file.".docker/mcp/registry.yaml".source = config.lib.file.mkOutOfStoreSymlink "/home/jmeskill/Projects/github/iamruinous/nix-config/hosts/pilaster/files/docker/mcp/registry.yaml";
  home.file.".docker/mcp/tools.yaml".source = config.lib.file.mkOutOfStoreSymlink "/home/jmeskill/Projects/github/iamruinous/nix-config/hosts/pilaster/files/docker/mcp/tools.yaml";

  home.stateVersion = "26.05";
}
