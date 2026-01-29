# Moltbot - Personal AI Assistant for Discord and WhatsApp
#
# Moltbot (formerly Clawdbot) is a personal AI assistant that connects
# to messaging platforms. This configuration sets up Discord and WhatsApp
# deployment using Anthropic Claude as the AI provider.
#
# The moltbot home-manager module is configured in:
#   hosts/chassis/users/jmeskill/home-configuration.nix
#
# This file defines:
#   1. The nixpkgs overlay (adds pkgs.clawdbot etc.)
#   2. The agenix secrets needed by the home-manager module
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
#   3. Pair: clawdbot channels login whatsapp (scan QR)
#
# References:
#   - https://github.com/moltbot/moltbot
#   - https://github.com/moltbot/nix-moltbot
{flake, lib, ...}: {
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

  age.secrets.chassis_moltbot_whatsapp_allowfrom = lib.mkIf (builtins.pathExists ./files/moltbot/whatsapp-allowfrom.age) {
    rekeyFile = ./files/moltbot/whatsapp-allowfrom.age;
    mode = "400";
    owner = "jmeskill";
    group = "users";
  };
}
