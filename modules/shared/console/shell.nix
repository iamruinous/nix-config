{
  lib,
  pkgs,
  ...
}: {
  # shell packages
  environment.systemPackages = with pkgs; [
    # prompt stuff
    figlet
    fortune
    lolcat
    toilet
  ];

  # Zsh configuration
  programs.zsh.enable = lib.mkDefault true;

  # Fish configuration
  programs.fish.enable = lib.mkDefault true;
}
