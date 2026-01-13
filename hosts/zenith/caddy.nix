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

      # n8n Development Environment (internal)
      # External access via Cloudflare tunnel (n8n.meskill.dev, n8h.meskill.dev)
      "n8n.meskill.dev" = {
        upstream = "n8n-dev:5678";
        description = "n8n development environment (internal)";
      };
    };

    # Complex routes with raw Caddy config
    rawRoutes = {
      # n8n webhooks only (restricted)
      "n8h.meskill.dev" = {
        description = "n8n webhooks only (restricted)";
        config = ''
          handle /webhook/* {
            reverse_proxy n8n-dev:5678
          }
          handle /mcp/* {
            reverse_proxy n8n-dev:5678
          }
          handle {
            abort
          }
        '';
      };
    };
  };

  # Caddy secrets (global config with ACME credentials)
  age.secrets.zenith_caddy_secrets = {
    rekeyFile = ./files/caddy/secrets.age;
    mode = "600";
  };
}
