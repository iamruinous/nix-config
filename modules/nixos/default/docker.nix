# virtualisation.docker.enable = true;
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.virtualisation.docker;
in {
  config = lib.mkIf cfg.enable {
    users.users.jmeskill.extraGroups = ["docker"]; # TODO: generalize user

    environment.systemPackages = with pkgs; [
      lazydocker
    ];
  };
}
