{perSystem, ...}: {
  nixpkgs.overlays = [
    (_final: _prev: {
      inherit (perSystem) self;
      agenix-helper = perSystem.self.agenix-helper;
      backup-docker-mariadb = perSystem.self.backup-docker-mariadb;
      backup-docker-postgres = perSystem.self.backup-docker-postgres;
      docker-mcp-gateway = perSystem.self.docker-mcp-gateway;
      forgejo-shell = perSystem.self.forgejo-shell;
      messy-restricted-shell = perSystem.self.messy-restricted-shell;
      nelko-pl70ebt = perSystem.self.nelko-pl70ebt;
      pinentry-1password = perSystem.self.pinentry-1password;
      ssh-agent-check = perSystem.self.ssh-agent-check;
    })
  ];
}
