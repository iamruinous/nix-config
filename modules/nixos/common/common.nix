{pkgs, ...}: {
  # System packages
  environment.systemPackages = with pkgs; [
    home-manager

    # utils
    cargo-binstall
    duf
    dust
    fd
    gnupg
    moor
    mosh
    procs
    rsync
    xplr
    xz

    # prompt stuff
    figlet
    fortune
    lolcat
    neofetch
    toilet
  ];

  # Zsh configuration
  programs.zsh.enable = true;

  # Fish configuration
  programs.fish.enable = true;
}
