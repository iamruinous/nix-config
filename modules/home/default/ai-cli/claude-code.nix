# ruinous.ai-cli.claude-code.enable = true;
#
# Manages Claude Code CLI configuration with:
# - CLI binary installation (Linux only, use brew on macOS)
# - Public settings (permissions, sandbox, announcements) synced via home-manager
#
# See docs/ai-cli-sync-reference.md for details on what files are synced.
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ai-cli.claude-code;
  claude_settings = flake + /files/configs/claude/settings.json;
  llmAgentsPkgs = flake.inputs.llm-agents.packages.${pkgs.system};
in {
  options.ruinous.ai-cli.claude-code = {
    enable = mkEnableOption "Claude Code CLI configuration management";
  };

  config = mkIf cfg.enable {
    # Install claude-code binary (Linux only - use brew on macOS)
    home.packages = mkIf pkgs.stdenv.isLinux [
      llmAgentsPkgs.claude-code
    ];

    # Sync public settings only - OAuth credentials must be obtained locally
    # per-machine since tokens cannot be shared across multiple machines
    home.file.".claude/settings.json".source = claude_settings;
  };
}
