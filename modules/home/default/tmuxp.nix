# tmuxp - declarative tmux session management
#
# Simplified interface: one command per window (no panes).
# Windows are ordered by list position.
#
# Usage:
#   ruinous.tmuxp = {
#     enable = true;
#     sessions.nix-config = {
#       startDirectory = "~/Projects/github/iamruinous/nix-config";
#       startCommands = ["direnv exec . true"];
#       windows = [
#         { name = "server"; command = "opencode serve --port 9500"; detached = true; }
#         { name = "opencode"; command = "sleep 2 && opencode attach http://localhost:9500"; focus = true; }
#         { name = "editor"; command = "nvim ."; }
#         { name = "shell"; }  # blank shell
#       ];
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

  # Convert window to tmuxp format
  windowToTmuxp = idx: win: let
    command = win.command or null;
    detached = win.detached or false;
    # If detached, run command in background and leave shell available
    pane =
      if command == null || command == ""
      then "blank"
      else if detached
      then "${command} &; disown"
      else command;
  in
    {
      window_name = win.name;
      window_index = idx;
      panes = [pane];
    }
    // optionalAttrs (win.focus or false) {focus = true;}
    // optionalAttrs (win.startDirectory or null != null) {start_directory = win.startDirectory;}
    // optionalAttrs (win.environment or {} != {}) {inherit (win) environment;};

  # Convert windows list to tmuxp windows list
  windowsToTmuxp = windows:
    imap0 windowToTmuxp windows;

  # Convert a session to tmuxp JSON
  sessionToJson = name: session: let
    sessionName =
      if session.sessionName != null
      then session.sessionName
      else name;
  in
    builtins.toJSON (
      {
        session_name = sessionName;
        windows = windowsToTmuxp (session.windows or []);
      }
      // optionalAttrs (session.startDirectory or null != null) {start_directory = session.startDirectory;}
      // optionalAttrs (session.startCommands or [] != []) {shell_command_before = session.startCommands;}
      // optionalAttrs (session.environment or {} != {}) {inherit (session) environment;}
      // optionalAttrs (session.beforeScript or null != null) {before_script = session.beforeScript;}
      // optionalAttrs (!(session.suppressHistory or true)) {suppress_history = session.suppressHistory;}
    );

  # Window type
  windowType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Window name";
        example = "editor";
      };

      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Command to run in the window (null or empty for blank shell)";
        example = "nvim .";
      };

      startDirectory = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override start directory for this window";
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables for this window";
      };

      detached = mkOption {
        type = types.bool;
        default = false;
        description = "Run command in background, leaving shell available";
      };

      focus = mkOption {
        type = types.bool;
        default = false;
        description = "Focus this window when session loads";
      };
    };
  };

  # Session type
  sessionType = types.submodule {
    options = {
      sessionName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override session name (defaults to attribute name)";
      };

      startDirectory = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Starting directory for the session";
        example = "~/Projects/my-app";
      };

      startCommands = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Commands to run before each window";
        example = ["direnv exec . true"];
      };

      beforeScript = mkOption {
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

      suppressHistory = mkOption {
        type = types.bool;
        default = true;
        description = "Suppress shell history for commands";
      };

      windows = mkOption {
        type = types.listOf windowType;
        default = [];
        description = ''
          Windows for this session. Order in list determines window index.
        '';
        example = literalExpression ''
          [
            { name = "server"; command = "npm run dev"; detached = true; }
            { name = "editor"; command = "nvim ."; focus = true; }
            { name = "shell"; }
          ]
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
            startDirectory = "~/Projects/github/iamruinous/nix-config";
            startCommands = ["direnv exec . true"];

            windows = [
              { name = "server"; command = "opencode serve --port 9500"; detached = true; }
              { name = "opencode"; command = "sleep 2 && opencode attach http://localhost:9500"; focus = true; }
              { name = "editor"; command = "nvim ."; }
              { name = "shell"; }
            ];
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.tmuxp];

    # Generate session files in ~/.config/tmuxp/
    xdg.configFile =
      mapAttrs' (
        name: session:
          nameValuePair "tmuxp/${name}.json" {
            text = sessionToJson name session;
          }
      )
      cfg.sessions;
  };
}
