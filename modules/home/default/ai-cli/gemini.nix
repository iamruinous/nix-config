# ruinous.ai-cli.gemini.enable = true;
#
# Manages Gemini CLI configuration with:
# - CLI binary installation (Linux only, use brew on macOS)
# - Public settings synced via home-manager
#
# Note: Extensions (~/.gemini/extensions/) are NOT managed - install them manually
# or via `gemini extension install <name>`
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
  cfg = config.ruinous.ai-cli.gemini;
  gemini_settings = flake + /files/configs/gemini/settings.json;
  llmAgentsPkgs = flake.inputs.llm-agents.packages.${pkgs.system};
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
    # Install gemini-cli binary and sync settings
    {
      # Install gemini-cli (Linux only - use brew on macOS)
      home.packages = mkIf pkgs.stdenv.isLinux [
        llmAgentsPkgs.gemini-cli
      ];

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
