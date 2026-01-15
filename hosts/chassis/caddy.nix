# Chassis Caddy configuration for OpenCode web services
#
# Uses native Caddy (not Docker) with Cloudflare DNS for ACME
# Routes are auto-generated from home-manager opencode-projects config
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Get OpenCode projects from jmeskill's home-manager config
  opencodeProjects = config.home-manager.users.jmeskill.ruinous.ai-cli.opencode-projects.projects or {};

  # Filter to projects with caddy.fqdn set and generate virtual hosts
  # Each project with caddy.fqdn creates: fqdn -> localhost:port
  caddyVirtualHosts = lib.filterAttrs (_: v: v != null) (
    lib.mapAttrs' (
      name: project:
        if project.caddy.fqdn != null
        then
          lib.nameValuePair project.caddy.fqdn {
            extraConfig = ''
              reverse_proxy http://localhost:${toString project.port}
            '';
          }
        else lib.nameValuePair name null
    )
    opencodeProjects
  );
  
  # Add codey-docs static site
  codeyDocsHost = {
    "codey.ruinous.ai" = {
      extraConfig = ''
        root * ${pkgs.codey-docs}
        file_server
        encode gzip
        try_files {path} {path}/ /index.html
        
        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          Referrer-Policy "strict-origin-when-cross-origin"
        }
      '';
    };
  };
  
  # Add messy-docs static site
  messyDocsHost = {
    "messy.ruinous.ai" = {
      extraConfig = ''
        root * ${pkgs.messy-docs}
        file_server
        encode gzip
        try_files {path} {path}/ /index.html
        
        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          Referrer-Policy "strict-origin-when-cross-origin"
        }
      '';
    };
  };
  
  # Add newsy-docs static site
  newsyDocsHost = {
    "newsy.ruinous.ai" = {
      extraConfig = ''
        root * ${pkgs.newsy-docs}
        file_server
        encode gzip
        try_files {path} {path}/ /index.html
        
        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          Referrer-Policy "strict-origin-when-cross-origin"
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
    # Merge OpenCode projects and docs sites
    virtualHosts = caddyVirtualHosts // codeyDocsHost // messyDocsHost // newsyDocsHost;
  };

  # Caddy environment secrets (Cloudflare API token)
  age.secrets.chassis_caddy_env = {
    rekeyFile = ./files/caddy/env.age;
    mode = "400";
    owner = "caddy";
    group = "caddy";
  };
}
