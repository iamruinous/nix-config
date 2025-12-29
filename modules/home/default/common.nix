{flake, ...}: {
  # import home.common by default
  imports = [
    flake.homeModules.common
  ];
}
