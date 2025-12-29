{flake, ...}: {
  # import shared.universal by default
  imports = [
    flake.sharedModules.universal
  ];
}
