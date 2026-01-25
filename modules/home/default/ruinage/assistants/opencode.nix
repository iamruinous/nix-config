# Ruinage OpenCode Assistant Integration
#
# This module provides:
# - Global OpenCode settings (ruinous.ruinage.assistants.opencode.*)
# - Harness configurations (oh-my-opencode, ruinagents)
# - Per-project OpenCode service generation
#
# OpenCode is the primary AI coding assistant, with optional harnesses:
# - oh-my-opencode: Agent orchestration, categories, LSP servers
# - ruinagents: AGENTS.md, skills, project context
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;
  opencodeAssistant = cfg.assistants.opencode or {};
in {
  options.ruinous.ruinage.assistants.opencode = {
    enable = mkEnableOption "OpenCode AI assistant";

    # Harness stubs - full implementation in TODO 5
    harnesses = {
      oh-my-opencode = {
        enable = mkEnableOption "oh-my-opencode harness for agent orchestration";
      };

      ruinagents = {
        enable = mkEnableOption "ruinagents harness for AGENTS.md and skills";
      };
    };
  };

  config = mkIf (cfg.enable && (opencodeAssistant.enable or false)) {
    # OpenCode integration will be implemented in TODOs 5-6
  };
}
