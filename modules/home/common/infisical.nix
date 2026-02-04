# Infisical integration for agenix-rekey (home-manager)
#
# Home-manager version of the Infisical module for fetching secrets
# during agenix-rekey operations. Mirrors the NixOS module interface
# but works in standalone home-manager contexts.
#
# Flow:
#   1. Agent runs with INFISICAL_TOKEN set
#   2. agenix-rekey invokes generators
#   3. Generators call ruinous.infisical.getScript to fetch secrets
#   4. Secrets are re-encrypted into .age files
#   5. Home-manager consumes only .age files (no Infisical dependency at runtime)
#
# Usage in a generator:
#   age.secrets."my-secret" = {
#     rekeyFile = ./secrets/my-secret.age;
#     generator.script = config.ruinous.infisical.mkGenerator {
#       name = "MY_SECRET_NAME";
#       path = "/shared";
#     };
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
  # Auth: Uses INFISICAL_TOKEN if set, otherwise falls back to user login
  infisicalGetScript = pkgs.writeShellScript "infisical-get" ''
    set -euo pipefail

    env="$1"
    path="$2"
    name="$3"

    # Set API URL from config or environment
    export INFISICAL_API_URL="''${INFISICAL_API_URL:-${cfg.apiUrl}}"
    export INFISICAL_DISABLE_UPDATE_CHECK=true

    # Check authentication: prefer INFISICAL_TOKEN, fall back to user login
    if [[ -z "''${INFISICAL_TOKEN:-}" ]]; then
      # Check if user is logged in
      if ! ${pkgs.infisical}/bin/infisical user >/dev/null 2>&1; then
        echo "Error: Not authenticated with Infisical." >&2
        echo "Either set INFISICAL_TOKEN or run: infisical login --domain ${cfg.apiUrl}" >&2
        exit 1
      fi
    fi

    exec ${pkgs.infisical}/bin/infisical secrets get "$name" \
      --projectId="${cfg.projectId}" \
      --env="$env" \
      --path="$path" \
      --plain \
      --silent
  '';
in {
  options.ruinous.infisical = {
    enable = mkEnableOption "Infisical integration for agenix-rekey (home-manager)";

    apiUrl = mkOption {
      type = types.str;
      default = "https://infisical.meskill.farm";
      description = "Infisical API URL.";
      example = "https://app.infisical.com";
    };

    projectId = mkOption {
      type = types.str;
      default = "f95d3144-22bb-4c95-9ee8-f3319d4924d5";
      description = "Infisical project ID for secrets.";
    };

    env = mkOption {
      type = types.str;
      default = "homelab";
      description = "Default Infisical environment for secrets.";
      example = "production";
    };

    path = mkOption {
      type = types.str;
      default = "/shared";
      description = "Default Infisical path for secrets.";
      example = "/services/myapp";
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
    # Returns a function that conforms to agenix-rekey's generator.script type:
    # { name, secret, lib, pkgs, file, deps, decrypt, ... }: "shell script string"
    mkGenerator = mkOption {
      type = types.functionTo (types.functionTo types.str);
      readOnly = true;
      default = {
        name,
        env ? cfg.env,
        path ? cfg.path,
      }:
        # Return a function that agenix-rekey will call with its standard arguments
        { pkgs, lib, ... }:
        ''
          # Set Infisical API URL
          export INFISICAL_API_URL="''${INFISICAL_API_URL:-${cfg.apiUrl}}"
          export INFISICAL_DISABLE_UPDATE_CHECK=true

          # Check authentication: prefer INFISICAL_TOKEN, fall back to user login
          if [[ -z "''${INFISICAL_TOKEN:-}" ]]; then
            # Check if user is logged in
            if ! ${pkgs.infisical}/bin/infisical user >/dev/null 2>&1; then
              echo "Error: Not authenticated with Infisical." >&2
              echo "Either set INFISICAL_TOKEN or run: infisical login --domain ${cfg.apiUrl}" >&2
              exit 1
            fi
          fi

          ${pkgs.infisical}/bin/infisical secrets get "${name}" \
            --projectId="${cfg.projectId}" \
            --env="${env}" \
            --path="${path}" \
            --plain \
            --silent
        '';
      description = ''
        Helper function to create agenix-rekey generator scripts.
        
        Returns a function compatible with agenix-rekey's generator.script option,
        which expects: { name, secret, lib, pkgs, file, deps, decrypt, ... }: "shell script"
        
        Usage:
          age.secrets."my-secret" = {
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
    # Add infisical CLI to user packages for manual operations
    home.packages = [pkgs.infisical];

    # Warning if agenix-rekey isn't properly configured
    warnings =
      if cfg.enable && (config.age.rekey.masterIdentities or []) == []
      then [
        ''
          ruinous.infisical (home-manager) is enabled but age.rekey.masterIdentities is empty.
          Ensure agenix-rekey is properly configured with master identities.
        ''
      ]
      else [];
  };
}
