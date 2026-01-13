# Armistice Caddy configuration using docker-caddy module
#
# Routes migrated from Caddyfile.age
# See files/caddy/README.md for route documentation
#
# Note: No routes configured - global settings only.
# Caddy is running but no reverse proxy routes are defined.
{config, ...}: {
  services.docker-caddy = {
    enable = true;
    secretsFile = config.age.secrets.armistice_caddy_secrets.path;
    email = "admin@meskill.network";

    # No routes configured
    routes = {};
    rawRoutes = {};
  };

  # Caddy secrets (global config with ACME credentials)
  age.secrets.armistice_caddy_secrets = {
    rekeyFile = ./files/caddy/secrets.age;
    mode = "600";
  };
}
