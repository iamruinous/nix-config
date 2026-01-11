{
  flake,
  pkgs,
  ...
}: {
  # import home.common by default
  imports = [
    flake.homeModules.common
  ];

  home.packages = with pkgs; [
    eztunnel
  ];
}
