{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    discord
    fastfetch
    google-chrome
    obsidian
    sbctl
    todoist-electron
  ];
}
