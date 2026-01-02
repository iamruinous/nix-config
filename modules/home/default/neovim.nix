{
  lib,
  pkgs,
  ...
}: let
  nvim_config = ../../../files/configs/nvim;
in {
  # Neovim text editor configuration
  programs.neovim = {
    enable = lib.mkDefault true;
    package = pkgs.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
  };

  xdg.configFile = {
    "nvim" = {
      source = "${nvim_config}";
      recursive = true;
    };
  };
}
