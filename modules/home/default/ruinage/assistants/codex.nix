# Codex Assistant Integration
#
# Stub for future implementation - prepares for ruinagents-codex packages
#
# This module provides:
# - Global Codex settings (ruinous.ruinage.assistants.codex.*)
# - Harness configurations (ruinagents)
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage.assistants.codex;
in {
  options.ruinous.ruinage.assistants.codex = {
    enable = mkEnableOption "Codex assistant configuration management";

    harnesses = {
      ruinagents = {
        enable = mkEnableOption "ruinagents harness for Codex";
      };
    };
  };

  config = mkIf cfg.enable {
    # Stub for future implementation - prepares for ruinagents-codex packages
  };
}
