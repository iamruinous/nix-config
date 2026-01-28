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
  # NOTE: ruinagents docs come from flake input. Once ruinagents is updated to
  # generate .etag files, change this to use etag_file_extensions .etag
  ruinagentsDocsHost = {
    "agents.ruinous.ai" = {
      extraConfig = ''
        root * ${ruinagentsDocs}
        file_server {
          precompressed gzip
          # Read ETags from .etag sidecar files (generated during Nix build)
          # This solves the Nix store mtime=1 problem where ETags don't change
          etag_file_extensions .etag
        }
        encode gzip
        try_files {path} {path}/ /index.html

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

        # HTML: short cache with revalidation (ETags from .etag files ensure freshness)
        header @html Cache-Control "public, max-age=60, must-revalidate"

        # Assets: longer cache with revalidation
        header @assets Cache-Control "public, max-age=3600, must-revalidate"
      '';
    };
  };

  # Ruinage aggregated documentation site (from home-manager ruinage.docs module)
  # Aggregated package in Nix store with symlinks to all project docs
  # Each project's docs package should include .etag sidecar files for cache busting
  ruinageDocsPackage = config.home-manager.users.jmeskill.ruinous.ruinage.docs.package;
  ruinageDocsHost = {
    "docs.ruinage.ai" = {
      extraConfig = ''
        root * ${ruinageDocsPackage}
        file_server {
          precompressed gzip
          # Read ETags from .etag sidecar files (generated during Nix build)
          # This solves the Nix store mtime=1 problem where ETags don't change
          etag_file_extensions .etag
        }
        encode gzip
        try_files {path} {path}/ {path}/index.html /index.html

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

        # HTML: short cache with revalidation (ETags from .etag files ensure freshness)
        header @html Cache-Control "public, max-age=60, must-revalidate"

        # Assets: longer cache with revalidation
        header @assets Cache-Control "public, max-age=3600, must-revalidate"
      '';
    };
  };

  # Budgey Assistant Dashboard - multi-CLI analytics dashboard (new budgey-assistant)
  budgeyAssistantDashboardHost = {
    "assistants.dashboard.ruinage.ai" = {
      extraConfig = ''
        reverse_proxy http://localhost:8889
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

  # Harmonia binary cache - Tailscale/local network only
  # Serves Nix store paths for private package caching
  harmoniaHost = {
    "cache.nix.meskill.farm" = {
      extraConfig = ''
        # Restrict to Tailscale IPs (100.x.x.x) and local network (10.55.x.x)
        @allowed {
          remote_ip 100.0.0.0/8 10.55.0.0/16 127.0.0.1/8
        }
        handle @allowed {
          reverse_proxy http://localhost:5000
        }
        handle {
          respond "Access denied - Tailscale or local network required" 403
        }
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
    # Merge OpenCode projects, docs sites, budgey assistant dashboard, ruinage docs, weaviate, and harmonia
    virtualHosts = caddyVirtualHosts // ruinagentsDocsHost // ruinageDocsHost // budgeyAssistantDashboardHost // weaviateHost // harmoniaHost;
  };

  # Caddy environment secrets (Cloudflare API token)
  age.secrets.chassis_caddy_env = {
    rekeyFile = ./files/caddy/env.age;
    mode = "400";
    owner = "caddy";
    group = "caddy";
  };
}
