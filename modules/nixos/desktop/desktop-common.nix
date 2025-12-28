{
  flake,
  pkgs,
  ...
}: {
  imports = [flake.nixosModules.default];

  environment.systemPackages = with pkgs; [
    discord
    fastfetch
    google-chrome
    obsidian
    sbctl
    todoist-electron
  ];
}
