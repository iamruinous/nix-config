{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.ruinous.tmux;
  powerkitCfg = cfg.powerkit;

  # N0FRILLS theme support - uses themes from tmux-powerkit package
  isN0frillsTheme = powerkitCfg.theme == "n0frills";
  n0frillsShared = {
    fg = "#eeeeee";
    bg = "#1c1c1c";
    border = "#3a3a3a";
    muted = "#626262";
    dim = "#4e4e4e";
    gray = "#8a8a8a";
  };
  n0frillsColorways = {
    ruin = {
      primary = "#d75fd7";
      accent = "#ffafd7";
      hot = "#ff5faf";
      highlight = "#5fd7d7";
    };
    siege = {
      primary = "#875fd7";
      accent = "#af87ff";
      hot = "#5f5fff";
      highlight = "#00afaf";
    };
    ghost = {
      primary = "#eeeeee";
      accent = "#bcbcbc";
      hot = "#eeeeee";
      highlight = "#ffaf00";
    };
  };
  n0frillsPalette =
    n0frillsShared
    // (lib.attrByPath [powerkitCfg.themeVariant] n0frillsColorways.ruin n0frillsColorways);

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
      default = null;
      description = "Secondary prefix key (set to null to disable)";
    };

    # Quick session picker (Ctrl-U by default, no prefix needed)
    sessionPicker = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable quick session picker keybinding";
      };

      keybinding = lib.mkOption {
        type = lib.types.str;
        default = "C-u";
        description = "Key to trigger session picker (root table, no prefix needed)";
      };
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
      description = "Allow passthrough for certain escape sequences (e.g., for image protocols, OSC52 clipboard support).";
    };

    # Keybindings - attrset for easy override/extension
    keybindings = lib.mkOption {
      type = lib.types.attrsOf keybindingType;
      default = {
        # Session navigation (overrides default [ = copy-mode, ] = paste-buffer)
        # Rationale: More ergonomic than ( and ) for frequent session switching
        prev-session = {
          key = "[";
          command = "switch-client -p";
        };
        next-session = {
          key = "]";
          command = "switch-client -n";
        };

        # Pane splitting (preserves current path)
        split-horizontal = {
          key = "|";
          command = "split-window -h -c \"#{pane_current_path}\"";
        };
        split-vertical = {
          key = "-";
          command = "split-window -v -c \"#{pane_current_path}\"";
        };

        # Window swapping
        swap-window-left = {
          key = "<";
          command = "swap-window -t -1 \\; select-window -t -1";
          repeat = true;
        };
        swap-window-right = {
          key = ">";
          command = "swap-window -t +1 \\; select-window -t +1";
          repeat = true;
        };

        # Refresh environment after deploy (re-sources profile to pick up new paths)
        refresh-env = {
          key = "E";
          command = "run-shell 'tmux set-environment -g PATH \"$(fish -lc \"echo \\$PATH\")\"' \\; display-message \"Environment refreshed\"";
        };

        # SSH agent refresh (interactive pane selection popup)
        ssh-agent-refresh = {
          key = "u";
          command = "display-popup -E \"${pkgs.ssh-agent-check}/bin/ssh-agent-refresh\"";
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

    # Doom Console - quick AI popup (Phase 1)
    doomConsole = {
      enable = lib.mkEnableOption "Doom Console quick AI popup";

      keybindings = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["C-`" "C-_"];
        description = "Keys to trigger doom console (root table, no prefix needed). C-_ is more compatible than C-/ across terminals.";
        example = ["F12"];
      };

      command = lib.mkOption {
        type = lib.types.str;
        default = "opencode";
        description = "Command to run in the popup";
        example = "opencode run";
      };

      width = lib.mkOption {
        type = lib.types.str;
        default = "80%";
        description = "Popup width";
      };

      height = lib.mkOption {
        type = lib.types.str;
        default = "60%";
        description = "Popup height";
      };
    };

    powerkit = {
      enable = lib.mkEnableOption "tmux-powerkit status bar framework" // {default = true;};

      theme = lib.mkOption {
        type = lib.types.str;
        default = "tokyo-night";
        description = ''
          Powerkit theme name. Use "n0frills" for the RUiNAGE design system theme.
          Other themes: tokyo-night, catppuccin, dracula, nord, gruvbox, etc.
        '';
      };

      themeVariant = lib.mkOption {
        type = lib.types.str;
        default = "night";
        description = ''
          Powerkit theme variant.
          For n0frills: ruin (default), siege, ghost
          For tokyo-night: night, day, storm
          For catppuccin: mocha, macchiato, frappe, latte
        '';
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
        default = "slant";
        description = "Separator style between status bar segments";
      };

      edgeSeparatorStyle = lib.mkOption {
        type = lib.types.enum ["normal" "rounded" "slant" "slantup" "trapezoid" "flame" "pixel" "honeycomb" "none" "same"];
        default = "slant";
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
    
    # Enable vim-style pane navigation (hjkl) and resizing (HJKL)
    # Replaces pain-control plugin
    customPaneNavigationAndResize = true;

    plugins = with pkgs.tmuxPlugins; [
      # Core functionality plugins
      copycat        # Regex search + predefined patterns (URLs, files, git hashes, IPs)
      
      # Keybinding discovery popup (like vim's which-key)
      {
        plugin = tmux-which-key;
        extraConfig = ''
          # Use XDG config directory to avoid read-only Nix store
          set -g @tmux-which-key-xdg-enable 1
          set -g @tmux-which-key-xdg-plugin-path ".config/tmux/tmux-which-key"
        '';
      }

      # Powerkit - modular status bar framework
      (lib.mkIf powerkitCfg.enable {
        plugin = pkgs.tmuxPlugins.tmux-powerkit;
        extraConfig = ''
          # Theme configuration
          ${lib.optionalString isN0frillsTheme ''
            set -g @powerkit_theme "n0frills"
            set -g @powerkit_theme_variant "${powerkitCfg.themeVariant}"
          ''}
          ${lib.optionalString (!isN0frillsTheme) ''
            set -g @powerkit_theme "${powerkitCfg.theme}"
            set -g @powerkit_theme_variant "${powerkitCfg.themeVariant}"
          ''}

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

      ${lib.optionalString cfg.doomConsole.enable (lib.concatMapStringsSep "\n" (key: ''
        # Doom Console - quick AI popup (${key}, no prefix)
        # Close with Ctrl-C or Escape
        bind -n ${key} display-popup -E -w ${cfg.doomConsole.width} -h ${cfg.doomConsole.height} "/etc/profiles/per-user/$USER/bin/${cfg.doomConsole.command}"'') cfg.doomConsole.keybindings)}

      ${lib.optionalString cfg.sessionPicker.enable ''
        # Quick session picker (${cfg.sessionPicker.keybinding}, no prefix)
        ${lib.optionalString isN0frillsTheme ''
          bind -n ${cfg.sessionPicker.keybinding} choose-tree -Zs -F "#{?pane_marked,#[fg=${n0frillsPalette.hot}]■ , }#[fg=${n0frillsPalette.primary}]#S #[fg=${n0frillsPalette.gray}]#W"
        ''}
        ${lib.optionalString (!isN0frillsTheme) ''
          bind -n ${cfg.sessionPicker.keybinding} choose-tree -Zs
        ''}
      ''}

      # Status bar position (can be overridden by theme)
      set -g status-position ${cfg.statusPosition}

      ${lib.optionalString isN0frillsTheme ''
        # N0FRILLS tmux UI surfaces (menus, prompts, popups, copy-mode, overlays)
        set -g message-style "fg=${n0frillsPalette.fg},bg=${n0frillsPalette.bg}"
        set -g message-command-style "fg=${n0frillsPalette.primary},bg=${n0frillsPalette.bg},bold"

        set -g mode-style "fg=${n0frillsPalette.bg},bg=${n0frillsPalette.primary},bold"
        set -g copy-mode-match-style "fg=${n0frillsPalette.bg},bg=${n0frillsPalette.highlight}"
        set -g copy-mode-current-match-style "fg=${n0frillsPalette.bg},bg=${n0frillsPalette.hot},bold"

        set -g menu-style "fg=${n0frillsPalette.fg},bg=${n0frillsPalette.bg}"
        set -g menu-selected-style "fg=${n0frillsPalette.bg},bg=${n0frillsPalette.primary},bold"
        set -g menu-border-style "fg=${n0frillsPalette.border},bg=${n0frillsPalette.bg}"

        set -g popup-style "fg=${n0frillsPalette.fg},bg=${n0frillsPalette.bg}"
        set -g popup-border-style "fg=${n0frillsPalette.primary},bg=${n0frillsPalette.bg}"
        set -g popup-border-lines "rounded"

        set -g display-panes-colour "${n0frillsPalette.muted}"
        set -g display-panes-active-colour "${n0frillsPalette.primary}"

        set -g clock-mode-colour "${n0frillsPalette.primary}"
      ''}

      ${lib.optionalString cfg.allowPassthrough ''
        # Allow passthrough for certain escape sequences (e.g., for image protocols, OSC52)
        set -g allow-passthrough on
      ''}

      # Enable clipboard support (required for OSC52)
      set -g set-clipboard on

      # --- TRACKPAD OPTIMIZATION ---
      # Prevent jump-to-bottom on mouse selection (stay in copy-mode with selection visible)
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-no-clear

      # Increase scroll speed: 3 lines per wheel event (default is 1)
      bind -T copy-mode-vi WheelUpPane send -N 3 -X scroll-up
      bind -T copy-mode-vi WheelDownPane send -N 3 -X scroll-down
      bind -T copy-mode WheelUpPane send -N 3 -X scroll-up
      bind -T copy-mode WheelDownPane send -N 3 -X scroll-down

      # Smart scroll: pass to mouse-aware apps (vim/less), else enter copy-mode
      bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
      bind -n WheelDownPane select-pane -t= \; send-keys -M

      # Additional user configuration
      ${cfg.extraConfig}
    '';
  };
}
