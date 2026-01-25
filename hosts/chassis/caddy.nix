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
  # Filter for projects with assistants.opencode.web.enable = true
  opencodeProjects = lib.filterAttrs (_: project:
    (project.assistants.opencode.enable or false) &&
    (project.assistants.opencode.web.enable or false)
  ) (config.home-manager.users.jmeskill.ruinous.ruinage.projects or {});

  # Auto-assign ports starting from 9500 for projects without explicit port
  # Sort project names for deterministic port assignment (same logic as opencode.nix)
  sortedProjectNames = lib.sort (a: b: a < b) (lib.attrNames opencodeProjects);
  projectPortMap = lib.listToAttrs (lib.imap0 (idx: projectName: {
    name = projectName;
    value = 9500 + idx;
  }) sortedProjectNames);

  getProjectPort = projectName: project:
    if project.assistants.opencode.web.port != null
    then project.assistants.opencode.web.port
    else projectPortMap.${projectName};

  # Generate virtual hosts from filtered projects
  # Each project with web.enable creates: fqdn -> localhost:port
  caddyVirtualHosts = lib.mapAttrs' (
    name: project:
      lib.nameValuePair project.assistants.opencode.web.fqdn {
        extraConfig = ''
          reverse_proxy http://localhost:${toString (getProjectPort name project)}
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

  # Ruinage aggregated documentation site (from home-manager ruinage.docs module)
  # Aggregated package in Nix store with symlinks to all project docs
  ruinageDocsPackage = config.home-manager.users.jmeskill.ruinous.ruinage.docs.package;
  ruinageDocsHost = {
    "docs.ruinage.ai" = {
      extraConfig = ''
        root * ${ruinageDocsPackage}
        file_server {
          precompressed gzip
        }
        encode gzip
        try_files {path} {path}/ {path}/index.html /index.html

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
    # Merge OpenCode projects, docs sites, budgey dashboard, ruinage docs, and weaviate
    virtualHosts = caddyVirtualHosts // ruinagentsDocsHost // ruinageDocsHost // budgeyDashboardHost // weaviateHost;
  };

  # Caddy environment secrets (Cloudflare API token)
  age.secrets.chassis_caddy_env = {
    rekeyFile = ./files/caddy/env.age;
    mode = "400";
    owner = "caddy";
    group = "caddy";
  };
}
