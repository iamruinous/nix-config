# Ruinage Kimaki Assistant Integration
#
# This module provides:
# - Global Kimaki settings (ruinous.ruinage.assistants.kimaki.*)
# - Kimaki service generation
# - Auto-discovery of projects with namespaces.kimaki.enable
#
# Kimaki is a Discord bot that provides AI coding assistance,
# automatically registering projects from the kimaki namespace.
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;
  kimakiAssistant = cfg.assistants.kimaki or {};
in {
  options.ruinous.ruinage.assistants.kimaki = {
    enable = mkEnableOption "Kimaki Discord bot assistant";
  };

  config = mkIf (cfg.enable && (kimakiAssistant.enable or false)) {
    # Kimaki integration will be implemented in TODO 7
  };
}
