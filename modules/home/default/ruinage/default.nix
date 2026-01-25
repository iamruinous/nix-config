# Ruinage - Repository-First Project Configuration
#
# This module provides a unified system for managing AI coding projects:
# - Repository-first project definitions (git URL is the key)
# - Multi-namespace cloning (ruinage, kimaki)
# - Multi-assistant support (opencode, kimaki, claude-code, gemini, codex)
# - Automatic service generation, tmuxp sessions, direnv, budgey integration
#
# Usage:
#   ruinous.ruinage = {
#     enable = true;
#
#     # Global assistant settings (inherited by all projects)
#     assistants.opencode = {
#       enable = true;
#       harnesses.oh-my-opencode.enable = true;
#       harnesses.ruinagents.enable = true;
#     };
#
#     # Project definitions
#     projects.nix-config = {
#       repo = "nix-config";
#       owner = "iamruinous";
#       forge = "github.com";
#
#       # Clone to these namespaces
#       namespaces.ruinage.enable = true;
#       namespaces.kimaki.enable = true;
#
#       # Enable assistants for this project
#       assistants.opencode = {
#         enable = true;
#         port = 9500;
#         caddy.fqdn = "nix-config.oc.ruinous.ai";
#       };
#     };
#   };
#
# See also:
# - types.nix: Type definitions for projects and assistants
# - projects.nix: Project processing and auto-clone logic
# - assistants/opencode.nix: OpenCode integration
# - assistants/kimaki.nix: Kimaki Discord bot integration
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.ruinage;
in {
  options.ruinous.ruinage = {
    enable = mkEnableOption "Ruinage repository-first project management";
  };

  config = mkIf cfg.enable {
    # Module implementation will be added in subsequent TODOs
  };
}
