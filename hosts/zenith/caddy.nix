# Zenith Caddy configuration using docker-caddy module
#
# Routes migrated from Caddyfile.age
# See files/caddy/README.md for route documentation
#
# NOTE: OpenCode web services moved to chassis (native Caddy)
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
      # llama.cpp API (zenith-specific, legacy Ollama domain)
      "zenith.ollama.meskill.farm" = {
        upstream = "llama-cpp:8000";
        description = "llama.cpp API (zenith-specific, Ollama-compatible)";
        extraConfig = ''
          header_up Host localhost
        '';
      };

      # llama.cpp API (generic, legacy Ollama domain)
      "ollama.x.meskill.farm" = {
        upstream = "llama-cpp:8000";
        description = "llama.cpp API (generic, Ollama-compatible)";
        extraConfig = ''
          header_up Host localhost
        '';
      };

      # Model Context Protocol gateway
      "mcp.x.meskill.farm" = {
        upstream = "mcp-gateway:8080";
        description = "Model Context Protocol gateway";
      };

      # llama.cpp OpenAI-compatible API (legacy vLLM domain)
      "zenith.vllm.ruinous.ai" = {
        upstream = "llama-cpp:8000";
        description = "llama.cpp OpenAI-compatible API";
      };

      # Open WebUI chat interface (ruinous.ai)
      "zenith.ui.ruinous.ai" = {
        upstream = "open-webui:8080";
        description = "Open WebUI chat interface (ruinous.ai)";
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

      # Weaviate development vector database
      "weaviate.meskill.dev" = {
        upstream = "weaviate-dev:8080";
        description = "Weaviate development vector database";
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
