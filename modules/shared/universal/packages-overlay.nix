# Shared overlay for custom packages
# Used by both NixOS/Darwin (via overlay.nix) and standalone home-manager configs
#
# Usage: import ./packages-overlay.nix {inherit perSystem flake;}
{
  perSystem,
  flake,
}: final: prev: {
  inherit (perSystem) self;
  agenix-helper = perSystem.self.agenix-helper;
  backup-docker-mariadb = perSystem.self.backup-docker-mariadb;
  backup-docker-postgres = perSystem.self.backup-docker-postgres;
  chat-organizer = perSystem.self.chat-organizer;
  gocmitra = perSystem.self.gocmitra;
  docker-image-updater = perSystem.self.docker-image-updater;
  docker-mcp-gateway = perSystem.self.docker-mcp-gateway;
  eztunnel = perSystem.self.eztunnel;
  forgejo-mcp = perSystem.self.forgejo-mcp;
  forgejo-shell = perSystem.self.forgejo-shell;
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
}
