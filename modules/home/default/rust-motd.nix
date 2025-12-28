# rust-motd configuration for login info display
# Works on both NixOS and Darwin via home-manager
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.ruinous.rust-motd;
in {
  options.ruinous.rust-motd = {
    enable = lib.mkEnableOption "rust-motd system info display on login";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.rust-motd];

    # Use config file from repository
    xdg.configFile."rust-motd/config.toml".source = ../../../../files/configs/rust-motd/config.toml;
  };
}
