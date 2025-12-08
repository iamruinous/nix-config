# ruinous.tea.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.tea;
in {
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.tea
    ];

    age.secrets.tea_config = {
      rekeyFile = flake + /files/configs/tea/config.yml.age;
      path = "${config.home.homeDirectory}/.config/tea/config.yml";
      mode = "600";
      symlink = false;
    };
  };
}
