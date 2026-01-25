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

  # Overlay is only needed for standalone homeConfigurations (osConfig == null).
  # When home-manager is integrated with NixOS/Darwin, Blueprint sets useGlobalPkgs = true
  # and pkgs are inherited from the system config (which has the overlay already).
  # Setting nixpkgs.overlays with useGlobalPkgs is deprecated and will be removed.
  nixpkgs.overlays = lib.mkIf (osConfig == null) [
    (import ../../shared/universal/packages-overlay.nix {inherit perSystem flake;})
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
