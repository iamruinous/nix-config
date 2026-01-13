# Obelisk Caddy configuration using docker-caddy module
#
# Routes migrated from Caddyfile.age
# See files/caddy/README.md for route documentation
{config, ...}: {
  services.docker-caddy = {
    enable = true;
    secretsFile = config.age.secrets.obelisk_caddy_secrets.path;
    email = "admin@meskill.network";

    # Simple reverse proxy routes
    routes = {
      # Open WebUI (internal network)
      "ai.svc.farmhouse.meskill.network" = {
        upstream = "open-webui:8080";
        description = "Open WebUI (internal network)";
      };

      # Open WebUI (external)
      "ai.meskill.farm" = {
        upstream = "open-webui:8080";
        description = "Open WebUI (external)";
      };

      # Ollama API (internal network)
      "ollama.svc.farmhouse.meskill.network" = {
        upstream = "ollama:11434";
        description = "Ollama API (internal network)";
        extraConfig = ''
          header_up Host localhost
        '';
      };

      # Ollama API (external)
      "ollama.meskill.farm" = {
        upstream = "ollama:11434";
        description = "Ollama API (external)";
        extraConfig = ''
          header_up Host localhost
        '';
      };
    };

    # Complex routes with raw Caddy config
    rawRoutes = {
      # SPICE HTML5 client (internal network)
      "obelisk.svc.farmhouse.meskill.network" = {
        description = "SPICE HTML5 client (internal)";
        config = ''
          root * /static/spice-html5
          file_server
        '';
      };

      # SPICE HTML5 client (external)
      "obelisk.meskill.farm" = {
        description = "SPICE HTML5 client (external)";
        config = ''
          root * /static/spice-html5
          file_server
        '';
      };
    };
  };

  # Caddy secrets (global config with ACME credentials)
  age.secrets.obelisk_caddy_secrets = {
    rekeyFile = ./files/caddy/secrets.age;
    mode = "600";
  };
}
