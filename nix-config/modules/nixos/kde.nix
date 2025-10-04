# services.desktopManager.plasma6.enable = true;
{
  lib,
  config,
  flake,
  pkgs,
  ...
}: let
  cfg = config.services.desktopManager.plasma6;
in {
  imports = [
    flake.nixosModules.desktop-default
  ];

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.pipewire.enable = true;

    # Input settings
    services.libinput.enable = true;

    # Enable the KDE Plasma Desktop Environment.
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      extraPackages = with pkgs; [
        kdePackages.qtsvg
        kdePackages.qtmultimedia
        kdePackages.qtvirtualkeyboard
      ];
      theme = "sddm-astronaut-theme";
    };

    environment.systemPackages = with pkgs; [
      kdePackages.oxygen
      kdePackages.krohnkite
      (sddm-astronaut.override
        {
          embeddedTheme = "pixel_sakura";
        })
    ];
  };
}
