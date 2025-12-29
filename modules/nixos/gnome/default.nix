# services.desktopManager.gnome.enable = true;
{
  flake,
  config,
  lib,
  ...
}: let
  cfg = config.services.desktopManager.gnome;
in {
  imports = [flake.nixosModules.desktop];

  config = lib.mkIf cfg.enable {
    # Enable the GNOME Desktop Environment.
    services.displayManager.gdm.enable = true;
    services.displayManager.gdm.wayland = true;
  };
}
