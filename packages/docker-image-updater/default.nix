{pkgs, ...}: let
  script = pkgs.writeShellApplication {
    name = "docker-image-updater";

    runtimeInputs = with pkgs; [
      gum
      skopeo
      jq
      gnused
      gawk
      findutils
      gnugrep
      coreutils
    ];

    text = builtins.readFile ./docker-image-updater.sh;

    meta = {
      description = "Check for Docker image updates in NixOS container configurations";
      mainProgram = "docker-image-updater";
    };
  };
in
  script
