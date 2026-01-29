# Moltbot - Personal AI Assistant for Discord
#
# Moltbot (formerly Clawdbot) is a personal AI assistant that connects
# to messaging platforms. This configuration sets up a minimal Discord-only
# deployment using Anthropic Claude as the AI provider.
#
# The moltbot home-manager module is configured in:
#   hosts/chassis/users/jmeskill/home-configuration.nix
#
# This file defines:
#   1. The nixpkgs overlay (adds pkgs.clawdbot etc.)
#   2. The agenix secrets needed by the home-manager module
#
# References:
#   - https://github.com/moltbot/moltbot
#   - https://github.com/moltbot/nix-moltbot
{flake, ...}: {
  # Add the nix-moltbot overlay to make pkgs.clawdbot available
  nixpkgs.overlays = [
    flake.inputs.nix-moltbot.overlays.default
  ];

  # Secrets for moltbot - these are referenced by the home-manager config
  # The actual moltbot service configuration is in the user's home-manager config
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
}
