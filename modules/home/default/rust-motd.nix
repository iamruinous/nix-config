# rust-motd configuration for login info display
# Works on both NixOS and Darwin via home-manager
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.ruinous.rust-motd;

  # Generate TOML config for rust-motd
  configFile = pkgs.writeText "rust-motd-config.toml" ''
    [global]
    progress_full_character = "━"
    progress_empty_character = "━"
    progress_prefix = ""
    progress_suffix = ""

    [uptime]
    prefix = "Uptime:"

    [memory]

    [filesystems]

    [last_login]

    [command.fortune]
    command = "${pkgs.fortune}/bin/fortune -s"
  '';
in {
  options.ruinous.rust-motd = {
    enable = lib.mkEnableOption "rust-motd system info display on login";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.rust-motd];

    # Create config directory and file
    xdg.configFile."rust-motd/config.toml".source = configFile;
  };
}
