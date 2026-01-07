# ruinous.ai-cli.gemini.enable = true;
#
# Manages Gemini CLI configuration with:
# - Public settings synced via home-manager
# - OAuth credentials encrypted with agenix
# - MCP OAuth tokens encrypted with agenix
#
# Note: Extensions (~/.gemini/extensions/) are NOT managed - install them manually
# or via `gemini extension install <name>`
#
# See docs/ai-cli-sync-reference.md for details on what files are synced.
{
  config,
  lib,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.ai-cli.gemini;
  gemini_settings = flake + /files/configs/gemini/settings.json;
in {
  options.ruinous.ai-cli.gemini = {
    enable = mkEnableOption "Gemini CLI configuration management";

    email = mkOption {
      type = types.str;
      default = "";
      description = "Google account email for Gemini. If empty, google_accounts.json won't be managed.";
    };

  };

  config = mkIf cfg.enable (mkMerge [
    # Sync public settings only - OAuth credentials must be obtained locally
    # per-machine since tokens cannot be shared across multiple machines
    {
      # Main settings file
      home.file.".gemini/settings.json".source = gemini_settings;
    }

    # Optionally manage google_accounts.json (contains email)
    (mkIf (cfg.email != "") {
      home.file.".gemini/google_accounts.json".text = builtins.toJSON {
        active = cfg.email;
        old = [];
      };
    })
  ]);
}
