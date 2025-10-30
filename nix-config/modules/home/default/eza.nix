{lib, ...}: let
  eza_config = ../../../files/configs/eza;
in {
  # Install eza via home-manager module
  programs.eza = {
    enable = lib.mkDefault true;
    enableFishIntegration = true;
    enableBashIntegration = true;

    icons = "auto";
    colors = "auto";
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--group"
      "--all"
    ];
  };

  xdg.configFile = {
    "eza" = {
      source = "${eza_config}";
      recursive = true;
    };
  };
}
