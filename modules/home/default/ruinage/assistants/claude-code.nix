# Claude Code Assistant Integration
#
# Stub for future implementation - prepares for ruinagents-claude-code packages
#
# This module provides:
# - Global Claude Code settings (ruinous.ruinage.assistants.claude-code.*)
# - Harness configurations (ruinagents)
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage.assistants.claude-code;
in {
  options.ruinous.ruinage.assistants.claude-code = {
    enable = mkEnableOption "Claude Code assistant configuration management";

    harnesses = {
      ruinagents = {
        enable = mkEnableOption "ruinagents harness for Claude Code";
      };
    };
  };

  config = mkIf cfg.enable {
    # Stub for future implementation - prepares for ruinagents-claude-code packages
  };
}
