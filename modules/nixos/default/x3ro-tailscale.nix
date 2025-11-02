# from https://github.com/NixOS/nixpkgs/issues/411980#issuecomment-3129215477
# config.x3ro.tailscale.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.x3ro.tailscale;
in {
  options = with lib; {
    x3ro.tailscale = {
      enable = mkEnableOption "Enable tailscale";

      useRoutingFeatures = mkOption {
        type = types.enum ["none" "client" "server" "both"];
        default = "server";
        description = ''
          See https://search.nixos.org/options?type=packages&show=services.tailscale.useRoutingFeatures

          When set to "server" or "both", it also enables `udp-gro-forwarding`
          when `x3ro.tailscale.publicInterface` is provided.
        '';
      };

      publicInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "lan0";
        description = ''
          To enable `udp-gro-forwarding`, the public facing interface must be
          provided. See
          https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration

          Find the public interface with this command:

          ```
          ip -o route get 8.8.8.8 | cut -f 5 -d " "
          ```
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = true;

    services.tailscale.useRoutingFeatures = cfg.useRoutingFeatures;

    system = lib.mkIf (!isNull cfg.publicInterface && builtins.elem cfg.useRoutingFeatures ["server" "both"]) {
      activationScripts."tailscale-udp-gro-forwarding".text = ''
        ${pkgs.ethtool}/bin/ethtool -K ${cfg.publicInterface} rx-udp-gro-forwarding on rx-gro-list off
      '';
    };
  };
}
