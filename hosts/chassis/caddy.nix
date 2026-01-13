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
    virtualHosts = caddyVirtualHosts;
  };

  # Caddy environment secrets (Cloudflare API token)
  age.secrets.chassis_caddy_env = {
    rekeyFile = ./files/caddy/env.age;
    mode = "400";
    owner = "caddy";
    group = "caddy";
  };
}
