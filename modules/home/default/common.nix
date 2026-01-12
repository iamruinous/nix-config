{
  flake,
  pkgs,
  lib,
  ...
}: {
  # import home.common by default
  imports = [
    flake.homeModules.common
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # Install bat via home-manager module
  programs.bat = {
    enable = lib.mkDefault true;
  };

  # Install bottom via home-manager module
  programs.bottom = {
    enable = lib.mkDefault true;
    settings = {
      flags = {
        avg_cpu = true;
        temperature_type = "c";
      };

      colors = {
        low_battery_color = "red";
      };
    };
  };

  home.packages = with pkgs; [
    eztunnel
  ];
}
