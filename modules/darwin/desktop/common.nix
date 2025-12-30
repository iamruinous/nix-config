{
  flake,
  lib,
  ...
}: {
  # import shared.universal by default
  imports = [
    flake.sharedModules.universal
  ];

  # Fish configuration
  programs.fish.enable = lib.mkDefault true;
}
