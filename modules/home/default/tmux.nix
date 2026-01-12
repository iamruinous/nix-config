{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.ruinous.tmux;
  powerkitCfg = cfg.powerkit;

  # Keybinding submodule type
  keybindingType = lib.types.submodule {
    options = {
      key = lib.mkOption {
        type = lib.types.str;
        description = "Key or key combination to bind";
        example = "r";
      };
      command = lib.mkOption {
        type = lib.types.str;
        description = "Command to execute when key is pressed";
        example = "source-file ~/.config/tmux/tmux.conf \\; display-message \"Config reloaded...\"";
      };
      table = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Key table (e.g., 'copy-mode-vi', 'root'). Use 'root' for bindings without prefix.";
        example = "copy-mode-vi";
      };
      repeat = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Allow the key to repeat";
      };
    };
  };

  # Helper to generate keybinding config from a single binding
  mkKeybind = name: bind: let
    tableFlag =
      if bind.table != null
      then "-T ${bind.table} "
      else "";
    repeatFlag =
      if bind.repeat
      then "-r "
      else "";
  in "bind-key ${repeatFlag}${tableFlag}${bind.key} ${bind.command}";

  # Generate all keybinding lines from attrset
  keybindingLines = lib.concatStringsSep "\n" (lib.mapAttrsToList mkKeybind cfg.keybindings);

  # Helper to convert bool to tmux on/off
  boolToOnOff = b:
    if b
    then "on"
    else "off";
in {
  options.ruinous.tmux = {
    statusPosition = lib.mkOption {
      type = lib.types.enum ["top" "bottom"];
      default = "top";
      description = "Position of the tmux status bar";
    };

    # Visual notification options
    visualActivity = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Display a message when activity occurs in a window";
    };

    visualBell = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Display a message when a bell occurs in a window";
    };

    visualSilence = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Display a message when silence occurs in a window";
    };

    monitorActivity = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Monitor windows for activity";
    };

    focusEvents = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Request focus events from the terminal";
    };

    bellAction = lib.mkOption {
      type = lib.types.enum ["any" "none" "current" "other"];
      default = "none";
      description = "Action to take on a bell in a window";
    };

    # Secondary prefix
    prefix2 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "C-u";
      description = "Secondary prefix key (set to null to disable)";
    };

    # Terminal features
    terminalFeatures = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["xterm-256color:RGB"];
      description = "Terminal features to enable (for true color support, etc.)";
    };

    # Allow passthrough
    allowPassthrough = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow passthrough for certain escape sequences (e.g., for image protocols)";
    };

    # Keybindings - attrset for easy override/extension
    keybindings = lib.mkOption {
      type = lib.types.attrsOf keybindingType;
      default = {
        # Vi copy mode bindings
        copy-mode-vi-begin-selection = {
          key = "v";
          command = "send-keys -X begin-selection";
          table = "copy-mode-vi";
        };
        copy-mode-vi-copy = {
          key = "y";
          command = "send-keys -X copy-selection-and-cancel";
          table = "copy-mode-vi";
        };

        # Shift+PageUp/Down for scrolling (root table = no prefix needed)
        scroll-up = {
          key = "S-PPage";
          command = "copy-mode -u";
          table = "root";
        };
        copy-mode-page-up = {
          key = "S-PPage";
          command = "send -X page-up";
          table = "copy-mode";
        };
        copy-mode-page-down = {
          key = "S-NPage";
          command = "send -X page-down";
          table = "copy-mode";
        };

        # Reorder windows (prefix + R)
        reorder-windows = {
          key = "R";
          command = "move-window -r \\; display-message \"Windows reordered...\"";
        };

        # Reload tmux config (prefix + r)
        reload-config = {
          key = "r";
          command = "source-file ~/.config/tmux/tmux.conf \\; display-message \"Config reloaded...\"";
        };

        # Session management
        new-session = {
          key = "S";
          command = "command-prompt -p \"New Session:\" \"new-session -A -s '%%'\"";
        };
        kill-session = {
          key = "K";
          command = "confirm kill-session";
        };
      };
      description = ''
        Attrset of tmux keybindings. Each binding specifies:
        - key: The key or key combination
        - command: The tmux command to run
        - table: Optional key table (copy-mode-vi, root, etc.). Use 'root' for -n (no prefix) bindings.
        - repeat: Whether the key can repeat (-r flag)

        Example to add a binding:
          ruinous.tmux.keybindings.my-binding = {
            key = "C-t";
            command = "new-window";
          };

        Example to override a default:
          ruinous.tmux.keybindings.reload-config.key = "C-r";

        Example to disable a default binding:
          ruinous.tmux.keybindings = lib.mkForce (lib.filterAttrs (n: v: n != "kill-session") config.ruinous.tmux.keybindings);
      '';
    };

    # Extra config for anything not covered
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional tmux configuration";
    };

    powerkit = {
      enable = lib.mkEnableOption "tmux-powerkit status bar framework" // {default = true;};

      theme = lib.mkOption {
        type = lib.types.str;
        default = "tokyo-night";
        description = "Powerkit theme name";
      };

      themeVariant = lib.mkOption {
        type = lib.types.str;
        default = "night";
        description = "Powerkit theme variant";
      };

      # Base plugins are always installed by default.
      # Use extraPlugins to add more without redefining the base set.
      # To override basePlugins entirely, use lib.mkForce.
      basePlugins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["cpu" "memory" "datetime" "ssh"];
        description = ''
          Base powerkit plugins that are always installed.
          These provide the core status bar functionality.

          To override completely (not recommended):
            ruinous.tmux.powerkit.basePlugins = lib.mkForce ["datetime"];
        '';
      };

      extraPlugins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          Additional powerkit plugins to add to the status bar.
          These are appended to basePlugins.

          Example - add battery indicator on laptops:
            ruinous.tmux.powerkit.extraPlugins = ["battery"];
        '';
        example = ["battery"];
      };

      separatorStyle = lib.mkOption {
        type = lib.types.enum ["normal" "rounded" "slant" "slantup" "trapezoid" "flame" "pixel" "honeycomb" "none"];
        default = "rounded";
        description = "Separator style between status bar segments";
      };

      edgeSeparatorStyle = lib.mkOption {
        type = lib.types.enum ["normal" "rounded" "slant" "slantup" "trapezoid" "flame" "pixel" "honeycomb" "none" "same"];
        default = "rounded";
        description = "Edge separator style for status bar";
      };

      elementsSpacing = lib.mkOption {
        type = lib.types.enum ["false" "true" "both" "windows" "plugins"];
        default = "false";
        description = "Spacing between status bar elements";
      };

      transparent = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable transparent background for status bar";
      };

      cpu = {
        warningThreshold = lib.mkOption {
          type = lib.types.int;
          default = 70;
          description = "CPU usage percentage to trigger warning state";
        };

        criticalThreshold = lib.mkOption {
          type = lib.types.int;
          default = 90;
          description = "CPU usage percentage to trigger critical state";
        };
      };

      datetime = {
        format = lib.mkOption {
          type = lib.types.str;
          default = "time-12h";
          description = "DateTime format (preset_1 = %Y-%m-%d %H:%M:%S)";
        };
      };

      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Additional powerkit configuration";
      };
    };
  };

  config.programs.tmux = {
    enable = lib.mkDefault true;
    shell = "${pkgs.fish}/bin/fish";
    mouse = true;
    aggressiveResize = true;
    keyMode = "vi";
    baseIndex = 1;
    terminal = "tmux-256color";
    historyLimit = 100000;
    escapeTime = 0;

    plugins = with pkgs.tmuxPlugins; [
      # Core functionality plugins
      better-mouse-mode
      copycat
      pain-control
      sensible
      yank

      # Powerkit - modular status bar framework
      (lib.mkIf powerkitCfg.enable {
        plugin = pkgs.tmuxPlugins.tmux-powerkit;
        extraConfig = ''
          # Theme configuration
          set -g @powerkit_theme "${powerkitCfg.theme}"
          set -g @powerkit_theme_variant "${powerkitCfg.themeVariant}"

          # Plugins to show (basePlugins + extraPlugins)
          set -g @powerkit_plugins "${lib.concatStringsSep "," (powerkitCfg.basePlugins ++ powerkitCfg.extraPlugins)}"

          # Separator styles
          set -g @powerkit_separator_style "${powerkitCfg.separatorStyle}"
          set -g @powerkit_edge_separator_style "${powerkitCfg.edgeSeparatorStyle}"

          # Spacing between elements
          set -g @powerkit_elements_spacing "${powerkitCfg.elementsSpacing}"

          # Transparent background
          set -g @powerkit_transparent "${lib.boolToString powerkitCfg.transparent}"

          # Status position
          set -g @powerkit_status_position "${cfg.statusPosition}"

          # CPU plugin settings
          set -g @powerkit_plugin_cpu_warning_threshold "${toString powerkitCfg.cpu.warningThreshold}"
          set -g @powerkit_plugin_cpu_critical_threshold "${toString powerkitCfg.cpu.criticalThreshold}"

          # DateTime format
          set -g @powerkit_plugin_datetime_format "${powerkitCfg.datetime.format}"

          # Additional user configuration
          ${powerkitCfg.extraConfig}
        '';
      })
    ];

    extraConfig = ''
      ${lib.optionalString (cfg.prefix2 != null) ''
        # Secondary prefix key
        set-option -g prefix2 ${cfg.prefix2}
      ''}

      # Visual notifications
      set-option -g visual-activity ${boolToOnOff cfg.visualActivity}
      set-option -g visual-bell ${boolToOnOff cfg.visualBell}
      set-option -g visual-silence ${boolToOnOff cfg.visualSilence}
      set-option -g focus-events ${boolToOnOff cfg.focusEvents}
      set-window-option -g monitor-activity ${boolToOnOff cfg.monitorActivity}
      set-option -g bell-action ${cfg.bellAction}

      # Terminal features
      ${lib.concatMapStringsSep "\n" (feat: "set -as terminal-features \",${feat}\"") cfg.terminalFeatures}

      # Keybindings
      ${keybindingLines}

      # Refresh SSH_AUTH_SOCK - opens popup for interactive pane selection
      bind u display-popup -E "${pkgs.ssh-agent-check}/bin/ssh-agent-refresh"

      # Status bar position (can be overridden by theme)
      set -g status-position ${cfg.statusPosition}

      ${lib.optionalString cfg.allowPassthrough ''
        # Allow passthrough for certain escape sequences (e.g., for image protocols)
        set -g allow-passthrough on
      ''}

      # Additional user configuration
      ${cfg.extraConfig}
    '';
  };
}
