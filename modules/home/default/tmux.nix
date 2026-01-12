{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.ruinous.tmux;
  powerkitCfg = cfg.powerkit;
in {
  options.ruinous.tmux = {
    statusPosition = lib.mkOption {
      type = lib.types.enum ["top" "bottom"];
      default = "top";
      description = "Position of the tmux status bar";
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

      plugins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["cpu" "memory" "datetime"];
        description = "List of powerkit plugins to display in the status bar";
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
        default = "true";
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
          default = "preset_1";
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
      resurrect
      sensible
      yank

      # Powerkit - modular status bar framework
      (lib.mkIf powerkitCfg.enable {
        plugin = pkgs.tmuxPlugins.tmux-powerkit;
        extraConfig = ''
          # Theme configuration
          set -g @powerkit_theme "${powerkitCfg.theme}"
          set -g @powerkit_theme_variant "${powerkitCfg.themeVariant}"

          # Plugins to show
          set -g @powerkit_plugins "${lib.concatStringsSep "," powerkitCfg.plugins}"

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
      # Secondary prefix key
      set-option -g prefix2 C-u

      # Visual notifications
      set-option -g visual-activity off
      set-option -g visual-bell off
      set-option -g visual-silence off
      set-option -g focus-events on
      set-window-option -g monitor-activity on
      set-option -g bell-action none

      # Terminal features for true color support
      set -as terminal-features ",xterm-256color:RGB"

      # Vi copy mode bindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # Shift+PageUp/Down for scrolling
      bind -n S-PPage copy-mode -u
      bind -T copy-mode S-PPage send -X page-up
      bind -T copy-mode S-NPage send -X page-down

      # Reorder windows (prefix + R)
      bind R move-window -r \; display-message "Windows reordered..."

      # Reload tmux config (prefix + r)
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded..."

      # Refresh SSH_AUTH_SOCK - opens popup for interactive pane selection
      bind u display-popup -E "${pkgs.ssh-agent-check}/bin/ssh-agent-refresh"

      # Session management
      bind S command-prompt -p "New Session:" "new-session -A -s '%%'"
      bind K confirm kill-session

      # Status bar position (can be overridden by theme)
      set -g status-position ${config.ruinous.tmux.statusPosition}

      # Allow passthrough for certain escape sequences (e.g., for image protocols)
      set -g allow-passthrough on
    '';
  };
}
