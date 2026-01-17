{perSystem, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      inherit (perSystem) self;
      agenix-helper = perSystem.self.agenix-helper;
      backup-docker-mariadb = perSystem.self.backup-docker-mariadb;
      backup-docker-postgres = perSystem.self.backup-docker-postgres;
      codey-agent-system = perSystem.self.codey-agent-system;
      codey-docs = perSystem.self.codey-docs;
      messy-docs = perSystem.self.messy-docs;
      newsy-docs = perSystem.self.newsy-docs;
      nate-docs = perSystem.self.nate-docs;
      libby-docs = perSystem.self.libby-docs;
      docker-image-updater = perSystem.self.docker-image-updater;
      docker-mcp-gateway = perSystem.self.docker-mcp-gateway;
      eztunnel = perSystem.self.eztunnel;
      forgejo-mcp = perSystem.self.forgejo-mcp;
      forgejo-shell = perSystem.self.forgejo-shell;
      messy-restricted-shell = perSystem.self.messy-restricted-shell;
      nelko-pl70ebt = perSystem.self.nelko-pl70ebt;
      osc-copy = perSystem.self.osc-copy;
      opencode-notifier-apprise = perSystem.self.opencode-notifier-apprise;
      pinentry-1password = perSystem.self.pinentry-1password;
      ruinous-login-hub = perSystem.self.ruinous-login-hub;
      ssh-agent-check = perSystem.self.ssh-agent-check;
      wezterm-codesigned = perSystem.self.wezterm-codesigned;

      # Extend tmuxPlugins with our custom plugins
      tmuxPlugins =
        prev.tmuxPlugins
        // {
          tmux-powerkit = perSystem.self.tmux-powerkit;
        };
    })
  ];
}
