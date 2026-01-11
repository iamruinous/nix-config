{
  pkgs,
  lib,
  ...
}: {
  # universal packages
  environment.systemPackages = with pkgs;
    [
      home-manager

      # config management
      agenix-helper
      ssh-agent-check

      # prompt stuff
      figlet
      fortune
      lolcat
      toilet

      # utils
      btop
      cargo-binstall
      duf
      dust
      fd
      glow
      gnupg
      gum
      mosh
      neofetch
      procs
      rsync
      wakeonlan
      xplr
      xz
    ]
    # Use moor if available, otherwise fall back to moar (for nixos-raspberrypi's pinned nixpkgs)
    ++ (
      if pkgs ? moor
      then [pkgs.moor]
      else lib.optional (pkgs ? moar) pkgs.moar
    );
}
