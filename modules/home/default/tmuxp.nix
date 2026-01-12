# tmuxp - declarative tmux session management
#
# This module provides idiomatic Nix configuration that maps directly to tmuxp's
# YAML structure. Sessions are saved to ~/.config/tmuxp/ for use with `tmuxp load`.
#
# Usage:
#   ruinous.tmuxp = {
#     enable = true;
#
#     # Session name is the attribute key
#     sessions.nix-config = {
#       start_directory = "~/Projects/github/iamruinous/nix-config";
#
#       # Window name is the attribute key
#       windows.main = {
#         layout = "main-vertical";
#         focus = true;
#         panes = [
#           "opencode --server"
#           "sleep 2 && opencode"
#         ];
#       };
#
#       windows.editor.panes = ["nvim ."];
#       windows.shell = {};  # Empty = blank shell
#     };
#   };
#
# Then use: tmuxp load nix-config
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.tmuxp;

  # Convert a pane to tmuxp format
  # Supports: string, list of strings, or attrset
  paneToTmuxp = pane:
    if builtins.isString pane then
      if pane == "" then "blank" else pane
    else if builtins.isList pane then
      { shell_command = pane; }
    else
      pane;

  # Convert windows attrset to tmuxp windows list
  windowsToTmuxp = windows:
    mapAttrsToList (name: win: 
      { window_name = name; panes = map paneToTmuxp (win.panes or ["blank"]); }
      // optionalAttrs (win.layout or null != null) { inherit (win) layout; }
      // optionalAttrs (win.focus or false) { focus = true; }
      // optionalAttrs (win.start_directory or null != null) { inherit (win) start_directory; }
      // optionalAttrs (win.shell_command_before or [] != []) { inherit (win) shell_command_before; }
      // optionalAttrs (win.options or {} != {}) { inherit (win) options; }
      // optionalAttrs (win.environment or {} != {}) { inherit (win) environment; }
    ) windows;

  # Convert a session to tmuxp JSON
  sessionToJson = name: session:
    let
      sessionName = if session.session_name != null then session.session_name else name;
    in
    builtins.toJSON (
      { session_name = sessionName; windows = windowsToTmuxp (session.windows or {}); }
      // optionalAttrs (session.start_directory or null != null) { inherit (session) start_directory; }
      // optionalAttrs (session.shell_command_before or [] != []) { inherit (session) shell_command_before; }
      // optionalAttrs (session.environment or {} != {}) { inherit (session) environment; }
      // optionalAttrs (session.before_script or null != null) { inherit (session) before_script; }
      // optionalAttrs (session.options or {} != {}) { inherit (session) options; }
      // optionalAttrs (session.global_options or {} != {}) { inherit (session) global_options; }
      // optionalAttrs (!(session.suppress_history or true)) { inherit (session) suppress_history; }
    );

  # Window type - flexible attrset matching tmuxp schema
  windowType = types.submodule {
    freeformType = types.attrsOf types.anything;
    options = {
      panes = mkOption {
        type = types.listOf (types.oneOf [
          types.str
          (types.listOf types.str)
          (types.attrsOf types.anything)
        ]);
        default = ["blank"];
        description = ''
          List of panes. Each pane can be:
          - A string command: "nvim ."
          - Empty string "" or "blank" for blank shell
          - A list of commands: ["cd /var/log" "ls -la"]
          - An attrset for full control: { shell_command = ["cmd1" "cmd2"]; focus = true; }
        '';
        example = [
          "nvim ."
          ["cd /var/log" "tail -f syslog"]
          { shell_command = "htop"; focus = true; }
        ];
      };

      layout = mkOption {
        type = types.nullOr (types.enum [
          "even-horizontal"
          "even-vertical"
          "main-horizontal"
          "main-vertical"
          "tiled"
        ]);
        default = null;
        description = "Tmux layout for this window";
      };

      focus = mkOption {
        type = types.bool;
        default = false;
        description = "Focus this window when session loads";
      };

      start_directory = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override start directory for this window";
      };

      shell_command_before = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Commands to run before each pane in this window";
      };

      options = mkOption {
        type = types.attrsOf types.anything;
        default = {};
        description = "Window-level tmux options";
        example = { automatic-rename = true; };
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables for this window";
      };
    };
  };

  # Session type - flexible attrset matching tmuxp schema
  sessionType = types.submodule {
    freeformType = types.attrsOf types.anything;
    options = {
      session_name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override session name (defaults to attribute name)";
      };

      start_directory = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Starting directory for the session";
        example = "~/Projects/my-app";
      };

      shell_command_before = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Commands to run before each pane";
        example = ["source .venv/bin/activate"];
      };

      before_script = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Script to run before session starts (must return 0)";
        example = "./bootstrap.sh";
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables for the session";
      };

      options = mkOption {
        type = types.attrsOf types.anything;
        default = {};
        description = "Session-level tmux options";
      };

      global_options = mkOption {
        type = types.attrsOf types.anything;
        default = {};
        description = "Global (server-wide) tmux options";
      };

      suppress_history = mkOption {
        type = types.bool;
        default = true;
        description = "Suppress shell history for pane commands";
      };

      windows = mkOption {
        type = types.attrsOf windowType;
        default = {};
        description = ''
          Windows for this session. Attribute name becomes window_name.
        '';
        example = literalExpression ''
          {
            editor = {
              panes = ["nvim ."];
              focus = true;
            };
            server = {
              layout = "even-horizontal";
              panes = ["npm run dev" "npm run test:watch"];
            };
            shell = {};  # blank shell
          }
        '';
      };
    };
  };

in {
  options.ruinous.tmuxp = {
    enable = mkEnableOption "tmuxp declarative session management";

    sessions = mkOption {
      type = types.attrsOf sessionType;
      default = {};
      description = ''
        tmuxp session definitions. Attribute name becomes the session name
        and the filename in ~/.config/tmuxp/.

        Use `tmuxp load <name>` to start a session.
      '';
      example = literalExpression ''
        {
          nix-config = {
            start_directory = "~/Projects/github/iamruinous/nix-config";

            windows.code = {
              layout = "main-vertical";
              focus = true;
              panes = [
                "opencode --server"
                "sleep 2 && opencode"
              ];
            };

            windows.editor.panes = ["nvim ."];
            windows.tests.panes = [""];
            windows.shell = {};
          };

          my-webapp = {
            start_directory = "~/Projects/webapp";
            shell_command_before = ["source .venv/bin/activate"];

            windows.app = {
              layout = "main-horizontal";
              panes = [
                "npm run dev"
                ["npm run test:watch"]
              ];
            };

            windows.shell = {};
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.tmuxp];

    # Generate session files in ~/.config/tmuxp/
    xdg.configFile = mapAttrs' (name: session:
      nameValuePair "tmuxp/${name}.json" {
        text = sessionToJson name session;
      }
    ) cfg.sessions;
  };
}
