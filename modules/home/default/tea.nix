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

  # Import config-management library
  configMgmt = import ../../../lib/config-management.nix {
    inherit lib pkgs config;
  };
in {
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.tea
    ];

    age.secrets.tea_config = {
      rekeyFile = flake + /files/configs/tea/config.yml.age;
      path = "${config.home.homeDirectory}/.config/tea/config.yml";
      mode = "600";
      symlink = true;
    };

    home.activation.manage-tea-config = configMgmt.manageFromTemplate {
      name = "tea-config";
      configDir = "${config.home.homeDirectory}/.config/tea";
      configFile = "config.yml";
      templateFile = config.age.secrets.tea_config.path;
    };
  };
}
