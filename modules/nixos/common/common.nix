{pkgs, ...}: {
  # System packages
  environment.systemPackages = with pkgs; [
    home-manager

    # config management
    agenix-helper

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

  # Bash configuration
  programs.bash.enable = true;

  # Zsh configuration
  programs.zsh.enable = true;

  # Fish configuration
  programs.fish.enable = true;
}
