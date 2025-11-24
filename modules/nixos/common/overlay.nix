{perSystem, ...}: {
  nixpkgs.overlays = [
    (_final: _prev: {
      inherit (perSystem) self;
      agenix-helper = perSystem.self.agenix-helper;
      docker-mcp-gateway = perSystem.self.docker-mcp-gateway;
      forgejo-shell = perSystem.self.forgejo-shell;
      messy-restricted-shell = perSystem.self.messy-restricted-shell;
      nelko-pl70ebt = perSystem.self.nelko-pl70ebt;
      ssh-agent-check = perSystem.self.ssh-agent-check;
    })
  ];
}
