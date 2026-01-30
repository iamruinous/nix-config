{
  config,
  lib,
  ...
}: let
  cfg = config.ruinous.raycast;
in {
  options.ruinous.raycast = {
    enable = lib.mkEnableOption "Raycast script commands";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."raycast/scripts/ask-ai.sh" = {
      executable = true;
      text = ''
        #!/bin/bash

        # @raycast.schemaVersion 1
        # @raycast.title Ask AI
        # @raycast.mode silent
        # @raycast.argument1 { "type": "text", "placeholder": "Question for AI", "optional": false }
        # @raycast.icon 🤖
        # @raycast.packageName AI Assistant

        QUERY="$1"

        QUERY="''${QUERY#ask:}"
        QUERY="''${QUERY#ai:}"
        QUERY="''${QUERY# }"

        osascript -e "tell application \"WezTerm\" to activate"
        sleep 0.3
        osascript <<EOF
        tell application "System Events"
            tell process "WezTerm"
                keystroke "n" using command down
                delay 0.2
                keystroke "opencode --prompt \"$QUERY\""
                keystroke return
            end tell
        end tell
        EOF
      '';
    };
  };
}
