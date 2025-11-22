{
  flake,
  config,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.default
  ];

  nixpkgs.overlays = [
    ../../../../modules/nixos/common/overlay.nix
  ];

  ruinous.openssh.tmux.attach.enable = true;

  home.file.".docker/cli-plugins/docker-mcp".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.docker-mcp-gateway}/bin/docker-mcp";

  home.stateVersion = "25.05";
}
