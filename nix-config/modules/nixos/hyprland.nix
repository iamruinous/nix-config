# program.hyprland.enable = true;
{
  pkgs,
  config,
  inputs,
  flake,
  lib,
  ...
}: let
  cfg = config.programs.hyprland;
  inherit (inputs) hyprland-qtutils hyprshell;
in {
  imports = [
    flake.inputs.walker.nixosModules.walker
    flake.nixosModules.desktop
  ];

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.pipewire.enable = true;

    environment.systemPackages = with pkgs; [
      hypridle
      hyprlock
      hyprpaper
      hyprpicker
      hyprland-qtutils.packages."${pkgs.system}".default
      hyprshell.packages.${pkgs.system}.default
    ];

    # Input settings
    services.libinput.enable = true;

    services.displayManager.gdm.enable = true;
    services.displayManager.gdm.wayland = true;

    # Enable the Hyprland DM
    programs.hyprland = {
      xwayland.enable = true;
    };

    # programs.hyprshell = {
    #   enable = true;
    # };

    programs.walker = {
      enable = true;
    };

    services.xserver.updateDbusEnvironment = true;
    # Enable security services
    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;
    security.pam.services = {
      hyprlock = {};
      gdm.enableGnomeKeyring = true;
    };
  };
}
