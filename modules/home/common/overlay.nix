{perSystem, ...}: {
  nixpkgs.overlays = [
    (_final: _prev: {
      inherit (perSystem) self;
      docker-mcp-gateway = perSystem.self.docker-mcp-gateway;
      nelko-pl70ebt = perSystem.self.nelko-pl70ebt;
      forgejo-shell = perSystem.self.forgejo-shell;
      messy-restricted-shell = perSystem.self.messy-restricted-shell;
      ssh-agent-check = perSystem.self.ssh-agent-check;
    })
  ];
}
