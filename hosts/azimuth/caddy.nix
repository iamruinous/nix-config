# Azimuth Caddy configuration using docker-caddy module
#
# Routes migrated from Caddyfile.age
# See files/caddy/README.md for route documentation
#
# NOTE: OpenCode web services moved to chassis (native Caddy)
{config, ...}: {
  services.docker-caddy = {
    enable = true;
    secretsFile = config.age.secrets.azimuth_caddy_secrets.path;
    email = "admin@meskill.network";

    # Extra volumes for Tailscale socket
    extraVolumes = [
      "/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock"
    ];

    # Simple reverse proxy routes
    routes = {
      # llama.cpp OpenAI-compatible API
      "azimuth.cpp.ruinous.ai" = {
        upstream = "llama-cpp:8000";
        description = "llama.cpp OpenAI-compatible API";
      };

      # Open WebUI chat interface (ruinous.ai)
      "azimuth.ui.ruinous.ai" = {
        upstream = "open-webui:8080";
        description = "Open WebUI chat interface (ruinous.ai)";
      };
    };
  };

  # Caddy secrets (global config with ACME credentials)
  age.secrets.azimuth_caddy_secrets = {
    rekeyFile = ./files/caddy/secrets.age;
    mode = "600";
  };
}
