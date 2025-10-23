{pkgs, ...}: {
  # Fonts configuration
  fonts.packages = with pkgs; [
    nerd-fonts.bigblue-terminal
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.monaspace
  ];
}
