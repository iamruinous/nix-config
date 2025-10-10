# virtualisation.arion.enable = true;
{
  lib,
  pkgs,
  flake,
  config,
  ...
}: let
  cfg = config.virtualisation.arion;
in {
  imports = [
    flake.inputs.arion.nixosModules.arion
  ];

  config = lib.mkIf cfg.enable {
    # Docker configuration
    virtualisation.docker.enable = true;
    # virtualisation.docker.rootless.enable = true;
    # virtualisation.docker.rootless.setSocketVariable = true;
    users.users.jmeskill.extraGroups = ["docker"]; # TODO: generalize user

    environment.systemPackages = with pkgs; [
      arion
      lazydocker
    ];
  };
}
