{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.tailscale;
in {
  # age.secrets.tailscale_client_secret.file = ./client_secret.age;

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ethtool
      networkd-dispatcher
    ];

    services.networkd-dispatcher = {
      enable = true;

      rules."50-tailscale" = {
        onState = [
          "routable"
        ];
        script = ''
          NETDEV="$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")"
          "${pkgs.ethtool}/sbin/ethtool" -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off
        '';
      };
    };

    services.tailscale = {
      # age.secrets.tailscale_client_secret.file = ./client_secret.age;
      # authKeyParameters.ephemeral = true;
      openFirewall = true;
      useRoutingFeatures = lib.mkDefault "server";

      extraUpFlags = [
        "--advertise-tags=tag:ruinnix"
      ];
    };
  };
}
