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
      eztunnel = perSystem.self.eztunnel;
      forgejo-mcp = perSystem.self.forgejo-mcp;
      forgejo-shell = perSystem.self.forgejo-shell;
      messy-restricted-shell = perSystem.self.messy-restricted-shell;
      nelko-pl70ebt = perSystem.self.nelko-pl70ebt;
      ssh-agent-check = perSystem.self.ssh-agent-check;
    })
  ];

  home.uid = lib.mkDefault osConfig.users.users.${config.home.username}.uid;
}
