# ruinous.opencode-web.firewall.enable = true;
#
# Opens firewall ports for OpenCode Web UI services.
# Configure the ports to match your home-manager opencode-web services.
#
# Example:
#   ruinous.opencode-web.firewall = {
#     enable = true;
#     ports = [18080 18081];
#   };
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.ruinous.opencode-web.firewall;
in {
  options.ruinous.opencode-web.firewall = {
    enable = mkEnableOption "OpenCode Web UI firewall ports";

    ports = mkOption {
      type = types.listOf types.port;
      default = [];
      description = "List of ports to open for OpenCode web services.";
      example = [18080 18081];
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = cfg.ports;
  };
}
