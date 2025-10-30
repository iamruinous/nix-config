{
  flake,
  pkgs,
  ...
}: {
  imports = [flake.nixosModules.default];

  environment.systemPackages = with pkgs; [
    sbctl
    fastfetch
    google-chrome
    obsidian
    todoist-electron
  ];
}
