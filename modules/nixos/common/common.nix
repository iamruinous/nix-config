{
  pkgs,
  lib,
  ...
}: {
  # System packages
  environment.systemPackages = with pkgs;
    [
      home-manager

      # config management
      agenix-helper
      ssh-agent-check

      # utils
      cargo-binstall
      duf
      dust
      fd
      gnupg
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
    ]
    # Use moor if available, otherwise fall back to moar (for nixos-raspberrypi's pinned nixpkgs)
    ++ (
      if pkgs ? moor
      then [pkgs.moor]
      else lib.optional (pkgs ? moar) pkgs.moar
    );

  # Zsh configuration
  programs.zsh.enable = true;

  # Fish configuration
  programs.fish.enable = true;
}
