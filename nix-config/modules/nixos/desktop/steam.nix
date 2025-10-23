# programs.steam.enable = true;
{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.programs.steam;
in {
  config = lib.mkIf cfg.enable {
    programs.steam = {
      package = pkgs.steam.override {
        extraPkgs = pkgs:
          with pkgs; [
            gamemode # Conditionally when `programs.gamemode.enable` is set.
          ];
      };
    };

    environment.systemPackages = with pkgs; [
      lutris
      heroic
    ];

    # programs.gamescope.enable = true;
    programs.gamemode.enable = true;
  };
}
