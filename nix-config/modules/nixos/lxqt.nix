# services.desktopManager.lxqt.enable = true;
{
  flake,
  config,
  lib,
  ...
}: let
  cfg = config.services.desktopManager.lxqt;
in {
  imports = [flake.nixosModules.desktop];

  config = lib.mkIf cfg.enable {
    # Enable the LXQt Desktop Environment.
    services.displayManager.lightdm.enable = true;
  };
}
