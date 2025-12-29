{
  lib,
  pkgs,
  ...
}: let
  nvim_config = ../../../files/configs/nvim;
in {
  xdg.configFile = {
    "nvim" = {
      source = "${nvim_config}";
      recursive = true;
    };
  };
}
