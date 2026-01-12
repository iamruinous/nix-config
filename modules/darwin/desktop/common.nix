{
  flake,
  lib,
  ...
}: {
  # import shared.universal by default
  imports = [
    flake.sharedModules.universal
  ];

  # direnv integration
  programs.direnv = {
    enable = lib.mkDefault true;
    silent = true;
  };

  # Fish configuration
  programs.fish.enable = lib.mkDefault true;
}
