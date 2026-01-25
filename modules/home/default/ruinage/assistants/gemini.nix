# Gemini Assistant Integration
#
# Stub for future implementation - prepares for ruinagents-gemini packages
#
# This module provides:
# - Global Gemini settings (ruinous.ruinage.assistants.gemini.*)
# - Harness configurations (ruinagents)
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage.assistants.gemini;
in {
  options.ruinous.ruinage.assistants.gemini = {
    enable = mkEnableOption "Gemini assistant configuration management";

    harnesses = {
      ruinagents = {
        enable = mkEnableOption "ruinagents harness for Gemini";
      };
    };
  };

  config = mkIf cfg.enable {
    # Stub for future implementation - prepares for ruinagents-gemini packages
  };
}
