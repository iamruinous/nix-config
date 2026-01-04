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

    syncCredentials = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to sync encrypted OAuth credentials. Requires agenix secrets to exist.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Always sync public settings
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

    # Optionally sync encrypted credentials
    (mkIf cfg.syncCredentials {
      age.secrets.gemini_oauth_creds = {
        rekeyFile = flake + /files/configs/gemini/oauth_creds.json.age;
        path = "${config.home.homeDirectory}/.gemini/oauth_creds.json";
        mode = "600";
        symlink = false;
      };

      age.secrets.gemini_mcp_oauth = {
        rekeyFile = flake + /files/configs/gemini/mcp-oauth-tokens.json.age;
        path = "${config.home.homeDirectory}/.gemini/mcp-oauth-tokens.json";
        mode = "600";
        symlink = false;
      };
    })
  ]);
}
