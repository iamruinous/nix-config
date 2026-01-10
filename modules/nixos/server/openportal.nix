# ruinous.openportal.firewall.enable = true;
#
# Opens firewall ports for OpenPortal services.
# OpenPortal uses two ports: one for the web UI and one for the OpenCode backend.
#
# Example:
#   ruinous.openportal.firewall = {
#     enable = true;
#     ports = [18080 19090];  # Web UI + OpenCode server
#   };
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.ruinous.openportal.firewall;
in {
  options.ruinous.openportal.firewall = {
    enable = mkEnableOption "OpenPortal firewall ports";

    ports = mkOption {
      type = types.listOf types.port;
      default = [];
      description = "List of ports to open for OpenPortal services.";
      example = [18080 19090];
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = cfg.ports;
  };
}
