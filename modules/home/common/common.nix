{
  osConfig,
  config,
  lib,
  flake,
  perSystem,
  ...
}: {
  imports = [
    flake.inputs.agenix.homeManagerModules.default
    flake.inputs.agenix-rekey.homeManagerModules.default
    (flake + /secrets)
  ];

  nixpkgs.overlays = [
    (_final: _prev: {
      inherit (perSystem) self;
      docker-mcp-gateway = perSystem.self.docker-mcp-gateway;
      nelko-pl70ebt = perSystem.self.nelko-pl70ebt;
      forgejo-shell = perSystem.self.forgejo-shell;
      messy-restricted-shell = perSystem.self.messy-restricted-shell;
      ssh-agent-check = perSystem.self.ssh-agent-check;
      eztunnel = perSystem.self.eztunnel;
    })
  ];

  home.uid = lib.mkDefault osConfig.users.users.${config.home.username}.uid;
}
