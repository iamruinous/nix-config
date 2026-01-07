# ruinous.ai-cli.claude-code.enable = true;
#
# Manages Claude Code CLI configuration with:
# - Public settings (permissions, sandbox, announcements) synced via home-manager
# - OAuth credentials encrypted with agenix
#
# See docs/ai-cli-sync-reference.md for details on what files are synced.
{
  config,
  lib,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ai-cli.claude-code;
  claude_settings = flake + /files/configs/claude/settings.json;
in {
  options.ruinous.ai-cli.claude-code = {
    enable = mkEnableOption "Claude Code CLI configuration management";
  };

  config = mkIf cfg.enable {
    # Sync public settings only - OAuth credentials must be obtained locally
    # per-machine since tokens cannot be shared across multiple machines
    home.file.".claude/settings.json".source = claude_settings;
  };
}
