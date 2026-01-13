# Zenith Caddy configuration using docker-caddy module
#
# Routes migrated from Caddyfile.age
# See files/caddy/README.md for route documentation
{config, ...}: {
  services.docker-caddy = {
    enable = true;
    secretsFile = config.age.secrets.zenith_caddy_secrets.path;
    email = "admin@meskill.network";

    # Extra volumes for Tailscale socket
    extraVolumes = [
      "/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock"
    ];

    # Simple reverse proxy routes
    routes = {
      # Open WebUI chat interface
      "ai.x.meskill.farm" = {
        upstream = "open-webui:8080";
        description = "Open WebUI chat interface";
      };

      # Ollama API (zenith-specific)
      "zenith.ollama.meskill.farm" = {
        upstream = "ollama:11434";
        description = "Ollama API (zenith-specific)";
        extraConfig = ''
          header_up Host localhost
        '';
      };

      # Ollama API (generic)
      "ollama.x.meskill.farm" = {
        upstream = "ollama:11434";
        description = "Ollama API (generic)";
        extraConfig = ''
          header_up Host localhost
        '';
      };

      # Model Context Protocol gateway
      "mcp.x.meskill.farm" = {
        upstream = "mcp-gateway:8080";
        description = "Model Context Protocol gateway";
      };

      # OpenCode development server
      "opencode.meskill.farm" = {
        upstream = "host.docker.internal:18080";
        description = "OpenCode development server";
      };

      # Dawarich timeline (internal)
      "timeline-int.meskill.farm" = {
        upstream = "dawarich-app:3000";
        description = "Dawarich timeline (internal)";
      };

      # Dawarich timeline (external)
      "timeline.meskill.farm" = {
        upstream = "dawarich-app:3000";
        description = "Dawarich timeline (external)";
      };

      # Nominatim geocoding
      "nominatim.meskill.farm" = {
        upstream = "nominatim:8080";
        description = "Nominatim geocoding";
      };

      # Nominatim geocoding (alt)
      "nominatim.x.meskill.farm" = {
        upstream = "nominatim:8080";
        description = "Nominatim geocoding (alt)";
      };
    };
  };

  # Caddy secrets (global config with ACME credentials)
  age.secrets.zenith_caddy_secrets = {
    rekeyFile = ./files/caddy/secrets.age;
    mode = "600";
  };
}
