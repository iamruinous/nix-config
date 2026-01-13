# TTY-Ruinous-Social Caddy configuration using docker-caddy module
#
# Routes migrated from Caddyfile.age
# See files/caddy/README.md for route documentation
#
# Note: Most services migrated to pilaster. Only files.ruinous.social remains.
{config, ...}: {
  services.docker-caddy = {
    enable = true;
    secretsFile = config.age.secrets.tty_ruinous_social_caddy_secrets.path;
    email = "admin@meskill.network";

    # Complex routes with raw Caddy config
    rawRoutes = {
      # Static file hosting (S3 proxy to Linode Object Storage)
      "files.ruinous.social" = {
        description = "Static file hosting (S3 proxy)";
        config = ''
          reverse_proxy https://us-east-1.linodeobjects.com {
            header_up Host us-east-1.linodeobjects.com
          }
        '';
      };
    };
  };

  # Caddy secrets (global config with ACME credentials)
  age.secrets.tty_ruinous_social_caddy_secrets = {
    rekeyFile = ./files/caddy/secrets.age;
    mode = "600";
  };
}
