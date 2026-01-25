# Chassis Caddy configuration for OpenCode web services
#
# Uses native Caddy (not Docker) with Cloudflare DNS for ACME
# Routes are auto-generated from home-manager opencode-projects config
{
  config,
  lib,
  pkgs,
  flake,
  ...
}: let
  # Ruinagents docs package from flake input
  ruinagentsDocs = flake.inputs.ruinagents.packages.${pkgs.system}.docs;
  # Get OpenCode projects from ruinage
  # Filter for projects with assistants.opencode.enable = true and caddy.fqdn set
  opencodeProjects = lib.filterAttrs (_: project:
    (project.assistants.opencode.enable or false) && 
    (project.assistants.opencode.caddy.fqdn or null) != null
  ) (config.home-manager.users.jmeskill.ruinous.ruinage.projects or {});

  # Generate virtual hosts from filtered projects
  # Each project with caddy.fqdn creates: fqdn -> localhost:port
  caddyVirtualHosts = lib.mapAttrs' (
    name: project:
      lib.nameValuePair project.assistants.opencode.caddy.fqdn {
        extraConfig = ''
          reverse_proxy http://localhost:${toString project.assistants.opencode.port}
        '';
      }
  ) opencodeProjects;
  
  # Add ruinagents-docs static site
  ruinagentsDocsHost = {
    "agents.ruinous.ai" = {
      extraConfig = ''
        root * ${ruinagentsDocs}
        file_server {
          precompressed gzip
        }
        encode gzip
        try_files {path} {path}/ /index.html

        # Cache busting: HTML files get short cache, assets get long cache with ETag
        @html {
          path *.html /
        }
        @assets {
          path *.css *.js *.woff *.woff2 *.ttf *.png *.jpg *.svg *.ico
        }

        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          Referrer-Policy "strict-origin-when-cross-origin"
        }

        # HTML: no-store (never cache - Nix store files have fixed timestamps so ETags don't change between deployments)
        header @html Cache-Control "no-store"

        # Assets: cache for 1 hour, but revalidate with ETag
        header @assets Cache-Control "public, max-age=3600, must-revalidate"
      '';
    };
  };

  # Budgey Dashboard - public token analytics dashboard
  budgeyDashboardHost = {
    "budgey.ruinous.ai" = {
      extraConfig = ''
        reverse_proxy http://localhost:8888
      '';
    };
  };

  # Weaviate vector database for budgey semantic search
  # REST API on weaviate.ruinous.ai (HTTP)
  # gRPC API on grpc.weaviate.ruinous.ai (HTTP/2 cleartext via h2c)
  weaviateHost = {
    "weaviate.ruinous.ai" = {
      extraConfig = ''
        reverse_proxy http://localhost:8080
      '';
    };
    "grpc.weaviate.ruinous.ai" = {
      extraConfig = ''
        reverse_proxy h2c://localhost:50051
      '';
    };
  };
in {
  # Open firewall for HTTP/HTTPS
  networking.firewall.allowedTCPPorts = [80 443];

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.1"];
      hash = "sha256-Zls+5kWd/JSQsmZC4SRQ/WS+pUcRolNaaI7UQoPzJA0=";
    };
    # Environment file with CLOUDFLARE_API_TOKEN
    environmentFile = config.age.secrets.chassis_caddy_env.path;
    globalConfig = ''
      acme_dns cloudflare {$CLOUDFLARE_API_TOKEN}
    '';
    # Merge OpenCode projects, docs sites, budgey dashboard, and weaviate
    virtualHosts = caddyVirtualHosts // ruinagentsDocsHost // budgeyDashboardHost // weaviateHost;
  };

  # Caddy environment secrets (Cloudflare API token)
  age.secrets.chassis_caddy_env = {
    rekeyFile = ./files/caddy/env.age;
    mode = "400";
    owner = "caddy";
    group = "caddy";
  };
}
