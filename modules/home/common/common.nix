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
      nelko-pl70ebt = perSystem.self.nelko-pl70ebt;
      ssh-agent-check = perSystem.self.ssh-agent-check;
    })
  ];

  # Set home.uid from osConfig if available, otherwise fall back to typical Linux UID
  # osConfig may be null or the user may not be defined in osConfig.users
  home.uid = lib.mkDefault (
    let
      userConfig = osConfig.users.users.${config.home.username} or null;
    in
      if userConfig != null && userConfig ? uid && userConfig.uid != null
      then userConfig.uid
      else 1000 # Default to typical first user UID on Linux
  );
}
