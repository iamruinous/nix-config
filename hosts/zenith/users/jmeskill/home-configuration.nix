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

  ruinous.rust-motd.enable = true;
  ruinous.openssh.tmux.attach.enable = true;
  ruinous.openssh.remote.forwarding.enable = true;

  home.file.".docker/cli-plugins/docker-mcp".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.docker-mcp-gateway}/bin/docker-mcp";
  # home.file.".ssh/id_codey_ed25519".source = config.age.secrets.jmeskill_codey_ssh_key.path;

  # MCP Gateway configuration files - copied as real files (not symlinks) for Docker access
  # Docker containers can't follow symlinks to paths outside their mounted volumes
  home.activation.mcpConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.docker/mcp/catalogs"
    cp -f ${mcpConfigDir}/catalogs/farm-catalog.yaml "$HOME/.docker/mcp/catalogs/farm-catalog.yaml"
    cp -f ${mcpConfigDir}/config.yaml "$HOME/.docker/mcp/config.yaml"
    cp -f ${mcpConfigDir}/registry.yaml "$HOME/.docker/mcp/registry.yaml"
    cp -f ${mcpConfigDir}/tools.yaml "$HOME/.docker/mcp/tools.yaml"
  '';

  systemd.user.tmpfiles.rules = [
    "L+    /home/jmeskill/.local/bin/op-ssh-sign -    -    -     - ${pkgs.openssh}/bin/ssh-keygen"
  ];

  ruinous.git.signing = let
    zenithKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOUbvhmSusPR35I4Su5pcfyLl1SU8gjc65Rcj6JcDi+";
  in {
    github = zenithKey;
    farmforge = zenithKey;
    misc = zenithKey;
    miscFormat = "ssh";
  };

  # age.secrets.jmeskill_codey_ssh_key = {
  #   rekeyFile = ../../../../users/jmeskill/id_codey_ed25519.age;
  #   mode = "600";
  # };

  home.stateVersion = "26.05";
}
