{lib, ...}: let
  khal_config = ../../../files/configs/khal/config;
in {
  # Install khal via home-manager module
  programs.khal = {
    enable = lib.mkDefault true;
  };

  xdg.configFile."khal/config".source = "${khal_config}";
}
