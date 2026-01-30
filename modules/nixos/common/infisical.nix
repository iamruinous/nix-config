# Infisical integration for agenix-rekey
#
# This module provides options for fetching secrets from Infisical
# during agenix-rekey operations. It exposes a helper script that
# generators can use to retrieve secrets from Infisical and re-encrypt
# them into .age files.
#
# Flow:
#   1. Agent runs with INFISICAL_TOKEN set
#   2. agenix-rekey invokes generators
#   3. Generators call ruinous.infisical.getScript to fetch secrets
#   4. Secrets are re-encrypted into .age files
#   5. NixOS hosts consume only .age files (no Infisical dependency at runtime)
#
# Usage in a generator:
#   age.secrets."my-secret" = {
#     file = ./secrets/my-secret.age;
#     generator.script = pkgs.writeShellScript "gen-my-secret" ''
#       ${config.ruinous.infisical.getScript} "$env" "$path" "MY_SECRET_NAME" > "$out"
#     '';
#   };
#
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.ruinous.infisical;

  # Helper script that fetches a secret from Infisical
  # Usage: infisical-get <env> <path> <secret-name>
  # Output: Secret value to stdout
  infisicalGetScript = pkgs.writeShellScript "infisical-get" ''
    set -euo pipefail

    env="$1"
    path="$2"
    name="$3"

    # Require INFISICAL_TOKEN to be set (service token or machine identity)
    if [[ -z "''${INFISICAL_TOKEN:-}" ]]; then
      echo "Error: INFISICAL_TOKEN environment variable must be set" >&2
      exit 1
    fi

    # Set API URL from config or environment
    export INFISICAL_API_URL="''${INFISICAL_API_URL:-${cfg.apiUrl}}"
    export INFISICAL_DISABLE_UPDATE_CHECK=true

    exec ${pkgs.infisical}/bin/infisical secrets get "$name" \
      --env="$env" \
      --path="$path" \
      --plain \
      --silent
  '';
in {
  options.ruinous.infisical = {
    enable = mkEnableOption "Infisical integration for agenix-rekey";

    apiUrl = mkOption {
      type = types.str;
      default = "https://infisical.meskill.farm";
      description = "Infisical API URL.";
      example = "https://app.infisical.com";
    };

    env = mkOption {
      type = types.str;
      default = "homelab";
      description = "Default Infisical environment for NixOS secrets.";
      example = "production";
    };

    path = mkOption {
      type = types.str;
      default = "/nixos";
      description = "Default Infisical path for NixOS secrets.";
      example = "/infrastructure/nixos";
    };

    getScript = mkOption {
      type = types.path;
      readOnly = true;
      default = infisicalGetScript;
      description = ''
        Path to the helper script for fetching secrets from Infisical.
        
        Usage: ''${config.ruinous.infisical.getScript} <env> <path> <secret-name>
        
        The script requires INFISICAL_TOKEN to be set in the environment.
        Output: Secret value written to stdout.
      '';
    };

    # Convenience function for generating agenix-rekey generator scripts
    mkGenerator = mkOption {
      type = types.functionTo types.path;
      readOnly = true;
      default = {
        name,
        env ? cfg.env,
        path ? cfg.path,
      }:
        pkgs.writeShellScript "agenix-gen-${name}" ''
          set -euo pipefail
          ${infisicalGetScript} "${env}" "${path}" "${name}" > "$out"
        '';
      description = ''
        Helper function to create agenix-rekey generator scripts.
        
        Usage:
          age.secrets."my-secret" = {
            file = ./secrets/my-secret.age;
            generator.script = config.ruinous.infisical.mkGenerator {
              name = "MY_SECRET_NAME";
              # Optional: override defaults
              # env = "production";
              # path = "/custom/path";
            };
          };
      '';
    };
  };

  config = mkIf cfg.enable {
    # Add infisical CLI to system packages for manual operations
    environment.systemPackages = [pkgs.infisical];

    # Provide defaults for age.rekey if not already set
    # This doesn't override per-secret settings, just provides fallback behavior
    warnings =
      if cfg.enable && config.age.rekey.masterIdentities == []
      then [
        ''
          ruinous.infisical is enabled but age.rekey.masterIdentities is empty.
          Ensure agenix-rekey is properly configured with master identities.
        ''
      ]
      else [];
  };
}
