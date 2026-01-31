# Openclaw - Personal AI Assistant for Discord and WhatsApp
#
# Openclaw (formerly Moltbot/Clawdbot) is a personal AI assistant that connects
# to messaging platforms. This configuration sets up Discord and WhatsApp
# deployment using Anthropic Claude as the AI provider.
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
#
# Migration: Moved from fork (github:iamruinous/nix-moltbot) - see issue #391
{
  flake,
  config,
  lib,
  pkgs,
  ...
}: {
  # Add the nix-openclaw overlay to make pkgs.openclaw available
  nixpkgs.overlays = [
    flake.inputs.nix-openclaw.overlays.default
  ];

  # Enable Infisical integration for agenix-rekey
  # Tokens are fetched from Infisical and re-encrypted to .age files during rekey
  ruinous.infisical.enable = true;

  # Secrets for openclaw - these are referenced by the home-manager config
  # The actual openclaw service configuration is in the user's home-manager config
  # NOTE: Secret names retain "moltbot" prefix for backwards compatibility with
  # existing .age files. The secret *values* are unchanged.
  age.secrets.chassis_moltbot_discord_token = {
    rekeyFile = ./files/moltbot/discord-token.age;
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  age.secrets.chassis_moltbot_anthropic_key = {
    rekeyFile = ./files/moltbot/anthropic-key.age;
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  age.secrets.chassis_moltbot_gateway_token = {
    rekeyFile = ./files/moltbot/gateway-token.age;
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  age.secrets.chassis_moltbot_whatsapp_allowfrom = lib.mkIf (builtins.pathExists ./files/moltbot/whatsapp-allowfrom.age) {
    rekeyFile = ./files/moltbot/whatsapp-allowfrom.age;
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Messy Discord bot token (separate bot for messy agent)
  # This enables cross-channel memory: messy-discord + whatsapp share the same agent
  age.secrets.chassis_moltbot_messy_discord_token = lib.mkIf (builtins.pathExists ./files/moltbot/messy-discord-token.age) {
    rekeyFile = ./files/moltbot/messy-discord-token.age;
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };

  # Codey Discord bot token (separate bot for codey agent - #ops channel)
  age.secrets.chassis_moltbot_codey_discord_token = lib.mkIf (builtins.pathExists ./files/moltbot/codey-discord-token.age) {
    rekeyFile = ./files/moltbot/codey-discord-token.age;
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
}
