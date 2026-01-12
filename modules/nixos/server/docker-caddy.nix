# Docker Caddy module with declarative route configuration
#
# This module allows defining Caddy reverse proxy routes in Nix,
# with sensitive global config (ACME credentials, etc.) stored separately
# in an agenix-encrypted file.
#
# The final Caddyfile is generated at activation time by prepending
# the secrets file to the generated routes.
#
# Usage:
#   services.docker-caddy = {
#     enable = true;
#     secretsFile = config.age.secrets.caddy_secrets.path;
#     email = "admin@example.com";
#
#     # Simple reverse proxy routes
#     routes = {
#       "app.example.com" = {
#         upstream = "app:8080";
#         description = "Main application";
#       };
#       "api.example.com api-int.example.com" = {
#         upstream = "api:3000";
#         description = "API service (internal and external)";
#       };
#       "ollama.example.com" = {
#         upstream = "ollama:11434";
#         description = "Ollama API";
#         extraConfig = ''
#           header_up Host localhost
#         '';
#       };
#     };
#
#     # Complex routes with raw Caddy config
#     rawRoutes = {
#       "matrix.example.com" = {
#         description = "Matrix homeserver with path-based routing";
#         config = ''
#           reverse_proxy /_matrix/maubot/* maubot:29316
#           reverse_proxy /_matrix/* synapse:8008
#           reverse_proxy /_synapse/client/* synapse:8008
#         '';
#       };
#     };
#   };
#
# Secrets file format (Caddyfile.secrets.age):
#   {
#     acme_dns cloudflare YOUR_API_TOKEN
#   }
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.docker-caddy;

  # Generate a simple reverse_proxy route block
  generateRoute = domains: routeCfg: let
    extraConfig =
      if routeCfg.extraConfig != null
      then " {\n    ${replaceStrings ["\n"] ["\n    "] routeCfg.extraConfig}\n  }"
      else "";
  in ''
    ${domains} {
      reverse_proxy ${routeCfg.upstream}${extraConfig}
    }
  '';

  # Generate a raw config route block
  generateRawRoute = domains: routeCfg: ''
    ${domains} {
      ${routeCfg.config}
    }
  '';

  # Generate all route blocks (simple + raw)
  simpleRoutes = mapAttrsToList generateRoute cfg.routes;
  rawRoutes = mapAttrsToList generateRawRoute cfg.rawRoutes;
  generatedRoutes = concatStringsSep "\n" (simpleRoutes ++ rawRoutes);

  # Script to generate the final Caddyfile at activation time
  generateCaddyfileScript = pkgs.writeShellScript "generate-docker-caddyfile" ''
    set -euo pipefail

    SECRETS_FILE="$1"
    OUTPUT_FILE="$2"
    EMAIL="${cfg.email}"

    # Create output directory if needed
    mkdir -p "$(dirname "$OUTPUT_FILE")"

    # Start with the secrets (global config block)
    if [ -f "$SECRETS_FILE" ]; then
      cat "$SECRETS_FILE" > "$OUTPUT_FILE"
    else
      echo "Warning: Secrets file $SECRETS_FILE not found, creating minimal global config" >&2
      echo "{" > "$OUTPUT_FILE"
      echo "  email $EMAIL" >> "$OUTPUT_FILE"
      echo "}" >> "$OUTPUT_FILE"
    fi

    # Append a newline and the generated routes
    cat >> "$OUTPUT_FILE" << 'ROUTES_EOF'

${generatedRoutes}
ROUTES_EOF

    # Set permissions
    chmod 600 "$OUTPUT_FILE"
  '';

  # Type for simple reverse_proxy routes
  routeType = types.submodule {
    options = {
      upstream = mkOption {
        type = types.str;
        description = "Upstream address (e.g., 'container:8080' or 'http://localhost:3000')";
        example = "app:8080";
      };

      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Human-readable description of this route (for documentation)";
        example = "Main web application";
      };

      extraConfig = mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = "Additional Caddy configuration inside the reverse_proxy block";
        example = ''
          header_up Host localhost
        '';
      };
    };
  };

  # Type for complex routes with raw Caddy config
  rawRouteType = types.submodule {
    options = {
      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Human-readable description of this route (for documentation)";
        example = "Matrix homeserver with path-based routing";
      };

      config = mkOption {
        type = types.lines;
        description = "Raw Caddy configuration for the route block body";
        example = ''
          reverse_proxy /_matrix/* synapse:8008
          reverse_proxy /_synapse/* synapse:8008
        '';
      };
    };
  };
in {
  options.services.docker-caddy = {
    enable = mkEnableOption "Docker Caddy with declarative routes";

    secretsFile = mkOption {
      type = types.path;
      description = ''
        Path to the agenix-decrypted secrets file containing the Caddy global config block.
        This file should contain sensitive configuration like ACME DNS credentials.

        Example contents:
          {
            acme_dns cloudflare YOUR_CLOUDFLARE_API_TOKEN
          }
      '';
      example = literalExpression "config.age.secrets.caddy_secrets.path";
    };

    email = mkOption {
      type = types.str;
      description = "Email address for ACME certificate notifications";
      example = "admin@example.com";
    };

    outputPath = mkOption {
      type = types.str;
      default = "/run/caddy/Caddyfile";
      description = "Path where the generated Caddyfile will be written";
    };

    image = mkOption {
      type = types.str;
      default = "ghcr.io/caddybuilds/caddy-cloudflare:2.10.2";
      description = "Docker image for Caddy with Cloudflare DNS plugin";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/data/docker/caddy";
      description = "Base directory for Caddy persistent data";
    };

    networks = mkOption {
      type = types.listOf types.str;
      default = ["proxynet" "servicenet"];
      description = "Docker networks to attach Caddy to";
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = ["--add-host=host.docker.internal:host-gateway"];
      description = "Extra options to pass to docker run";
    };

    extraVolumes = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional volume mounts for the Caddy container";
      example = ["/var/run/tailscale/tailscaled.sock:/var/run/tailscale/tailscaled.sock"];
    };

    routes = mkOption {
      type = types.attrsOf routeType;
      default = {};
      description = ''
        Simple Caddy reverse proxy routes.
        Keys are domain names (space-separated for multiple domains).
        Values define the upstream and optional extra configuration.
      '';
      example = literalExpression ''
        {
          "app.example.com" = {
            upstream = "app:8080";
            description = "Main application";
          };
          "ollama.example.com" = {
            upstream = "ollama:11434";
            description = "Ollama API";
            extraConfig = '''
              header_up Host localhost
            ''';
          };
        }
      '';
    };

    rawRoutes = mkOption {
      type = types.attrsOf rawRouteType;
      default = {};
      description = ''
        Complex Caddy routes with raw configuration.
        Use this for routes that need multiple handlers, matchers, or other
        advanced Caddy features that don't fit the simple reverse_proxy pattern.
        Keys are domain names (space-separated for multiple domains).
      '';
      example = literalExpression ''
        {
          "matrix.example.com" = {
            description = "Matrix homeserver with path-based routing";
            config = '''
              reverse_proxy /_matrix/maubot/* maubot:29316
              reverse_proxy /_matrix/* synapse:8008
              reverse_proxy /_synapse/client/* synapse:8008
            ''';
          };
          "n8h.example.com" = {
            description = "n8n webhooks only (restricted)";
            config = '''
              handle /webhook/* {
                reverse_proxy n8n:5678
              }
              handle {
                abort
              }
            ''';
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Open firewall ports
    networking.firewall.allowedTCPPorts = [80 443];
    networking.firewall.allowedUDPPorts = [443];

    # Generate Caddyfile at activation time
    system.activationScripts.docker-caddy-generate = {
      text = ''
        ${generateCaddyfileScript} "${cfg.secretsFile}" "${cfg.outputPath}"
      '';
      deps = ["agenix"];
    };

    # Docker container definition
    virtualisation.oci-containers.containers.caddy = {
      image = cfg.image;
      networks = cfg.networks;
      ports = [
        "80:80"
        "443:443"
        "443:443/udp"
      ];
      extraOptions = cfg.extraOptions;
      capabilities = {
        "NET_ADMIN" = true;
      };
      volumes =
        [
          "${cfg.outputPath}:/etc/caddy/Caddyfile:ro"
          "${cfg.dataDir}/site:/srv"
          "${cfg.dataDir}/data:/data"
          "${cfg.dataDir}/config:/config"
        ]
        ++ cfg.extraVolumes;
    };

    # Restart Caddy when the Caddyfile changes
    systemd.services.docker-caddy = {
      restartTriggers = [
        cfg.secretsFile
        generatedRoutes
      ];
      # Ensure Caddyfile is generated before container starts
      preStart = ''
        ${generateCaddyfileScript} "${cfg.secretsFile}" "${cfg.outputPath}"
      '';
    };
  };
}
