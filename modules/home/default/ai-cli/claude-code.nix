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

    syncCredentials = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to sync encrypted OAuth credentials. Requires agenix secrets to exist.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Always sync public settings
    {
      home.file.".claude/settings.json".source = claude_settings;
    }

    # Optionally sync encrypted credentials
    (mkIf cfg.syncCredentials {
      age.secrets.claude_credentials = {
        rekeyFile = flake + /files/configs/claude/credentials.json.age;
        path = "${config.home.homeDirectory}/.claude/.credentials.json";
        mode = "600";
        symlink = false;
      };
    })
  ]);
}
