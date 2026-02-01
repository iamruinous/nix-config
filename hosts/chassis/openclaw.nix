# Openclaw - Personal AI Assistant for Discord and WhatsApp
#
# Openclaw (formerly Moltbot/Clawdbot) is a personal AI assistant that connects
# to messaging platforms. This configuration sets up Discord and WhatsApp
# deployment using OpenAI GPT-4o as the primary AI provider with Claude as fallback.
#
# The openclaw home-manager module is configured in:
#   hosts/chassis/users/jmeskill/home-configuration.nix
#
# This file defines:
#   1. The nixpkgs overlay (adds pkgs.openclaw etc.)
#   2. The agenix secrets needed by the home-manager module
#   3. Infisical-sourced secrets for GitHub/Forgejo CLI access
#
# WhatsApp Setup:
#   1. Create the phone number secret:
#      echo "+15551234567" > /tmp/whatsapp-allowfrom.txt
#      agenix-helper unlock
#      agenix edit -i /tmp/whatsapp-allowfrom.txt hosts/chassis/files/moltbot/whatsapp-allowfrom.age
#      agenix rekey -a
#      rm /tmp/whatsapp-allowfrom.txt
#      agenix-helper lock
#   2. Deploy: home-manager switch --flake .#jmeskill@chassis
#   3. Pair: openclaw channels login whatsapp (scan QR)
#
# GitHub/Forgejo CLI Access (Infisical Integration):
#   Tokens are sourced from Infisical during agenix-rekey and encrypted
#   to .age files. This enables openclaw to:
#   - Create/manage issues on GitHub (gh CLI)
#   - Create/manage issues on forge.meskill.farm (tea CLI)
#
#   To regenerate secrets from Infisical:
#     agenix-helper unlock
#     agenix rekey -a  # Fetches from Infisical and re-encrypts
#     agenix-helper lock
#
# References:
#   - https://github.com/openclaw/openclaw
#   - https://github.com/openclaw/nix-openclaw
{
  flake,
  config,
  lib,
  pkgs,
  ...
}: {
  # Add the nix-openclaw overlay to make pkgs.openclaw available
  # Also patch openclaw-gateway to include missing templates (nix-openclaw#18)
  nixpkgs.overlays = [
    flake.inputs.nix-openclaw.overlays.default

    # Workaround for https://github.com/openclaw/nix-openclaw/issues/18
    # Templates are missing from the package, causing "Missing workspace template" errors
    (final: prev: {
      openclaw-gateway = prev.openclaw-gateway.overrideAttrs (oldAttrs: {
        installPhase = ''
          ${oldAttrs.installPhase}
          mkdir -p $out/lib/openclaw/docs/reference/templates
          cp -r $src/docs/reference/templates/* $out/lib/openclaw/docs/reference/templates/
        '';
      });
    })
  ];

  # Enable Infisical integration for agenix-rekey
  # Tokens are fetched from Infisical and re-encrypted to .age files during rekey
  ruinous.infisical.enable = true;

  # Secrets for openclaw - all sourced from Infisical
  # Host-specific secrets at /hosts/chassis/openclaw/
  # Service-specific (non-host) secrets at /services/openclaw/
  # NOTE: Secret names retain "moltbot" prefix for backwards compatibility

  # Discord bot token (default bot)
  age.secrets.chassis_moltbot_discord_token = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "DISCORD_TOKEN";
      path = "/hosts/chassis/openclaw";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Anthropic API key - service-specific (not shared with n8n/opencode)
  age.secrets.chassis_moltbot_anthropic_key = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "ANTHROPIC_API_KEY";
      path = "/services/openclaw";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Gateway authentication token
  age.secrets.chassis_moltbot_gateway_token = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "GATEWAY_TOKEN";
      path = "/hosts/chassis/openclaw";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # WhatsApp allowed phone numbers (E.164 format, newline-separated)
  age.secrets.chassis_moltbot_whatsapp_allowfrom = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "WHATSAPP_ALLOWFROM";
      path = "/hosts/chassis/openclaw";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Messy Discord bot token (separate bot for messy agent)
  # Enables cross-channel memory: messy-discord + whatsapp share the same agent
  age.secrets.chassis_moltbot_messy_discord_token = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "MESSY_DISCORD_TOKEN";
      path = "/hosts/chassis/openclaw";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Codey Discord bot token (separate bot for codey agent - #ops channel)
  age.secrets.chassis_moltbot_codey_discord_token = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "CODEY_DISCORD_TOKEN";
      path = "/hosts/chassis/openclaw";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # GitHub token for gh CLI - sourced from Infisical /shared
  # Enables openclaw to create/manage GitHub issues programmatically
  # Shared across services - see /infisical-secrets skill for structure
  age.secrets.chassis_moltbot_github_token = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "GITHUB_TOKEN";
      path = "/shared";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Forgejo token for tea CLI - sourced from Infisical /shared
  # Enables openclaw to create/manage issues on forge.meskill.farm
  # Shared across services - see /infisical-secrets skill for structure
  age.secrets.chassis_moltbot_forgejo_token = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "FORGEJO_TOKEN";
      path = "/shared";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # OpenAI API key for openclaw - sourced from Infisical /services/openclaw
  # Service-specific key (not shared with other services like n8n/opencode)
  age.secrets.chassis_openclaw_openai_key = {
    generator.script = config.ruinous.infisical.mkGenerator {
      name = "OPENAI_API_KEY";
      path = "/services/openclaw";
    };
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };
}
