# services.desktopManager.xfce.enable = true;
{
  flake,
  config,
  lib,
  ...
}: let
  cfg = config.services.desktopManager.xfce;
in {
  imports = [flake.nixosModules.desktop];

  config = lib.mkIf cfg.enable {
    # Enable the XFCE Desktop Environment.
    services.displayManager.lightdm.enable = true;
  };
}
