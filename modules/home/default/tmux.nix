{
  lib,
  pkgs,
  config,
  ...
}: {
  options.ruinous.tmux = {
    statusPosition = lib.mkOption {
      type = lib.types.enum ["top" "bottom"];
      default = "bottom";
      description = "Position of the tmux status bar";
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

      # Tokyo Night theme
      {
        plugin = tokyo-night-tmux;
        extraConfig = ''
          # Theme variant: night (default), storm, or day
          set -g @tokyo-night-tmux_theme night

          # Number styles: digital, roman, fsquare, hsquare, dsquare, super, sub
          set -g @tokyo-night-tmux_window_id_style digital
          set -g @tokyo-night-tmux_pane_id_style hsquare
          set -g @tokyo-night-tmux_zoom_id_style dsquare

          # Date/time widget
          set -g @tokyo-night-tmux_show_datetime 1
          set -g @tokyo-night-tmux_date_format YMD
          set -g @tokyo-night-tmux_time_format 24H

          # Path widget
          set -g @tokyo-night-tmux_show_path 1
          set -g @tokyo-night-tmux_path_format relative

          # Git widget (requires jq, gh/glab)
          set -g @tokyo-night-tmux_show_wbg 0

          # Hostname widget
          set -g @tokyo-night-tmux_show_hostname 1
        '';
      }

      # Powerkit - modular status bar framework with tokyo-night theme
      {
        plugin = pkgs.tmux-powerkit;
        extraConfig = ''
          # Use Tokyo Night theme from powerkit
          set -g @powerkit_theme "tokyo-night"
          set -g @powerkit_theme_variant "night"

          # Plugins to show (customize as needed)
          set -g @powerkit_plugins "git,cpu,memory,datetime"

          # Separator style: normal, rounded, slant, flame, pixel, honeycomb
          set -g @powerkit_separator_style "rounded"

          # Spacing between elements
          set -g @powerkit_elements_spacing "both"

          # Transparent background
          set -g @powerkit_transparent "false"

          # Status position
          set -g @powerkit_status_position "${config.ruinous.tmux.statusPosition}"

          # Git plugin settings
          set -g @powerkit_plugin_git_show_branch "true"
          set -g @powerkit_plugin_git_show_files "true"
          set -g @powerkit_plugin_git_max_length "30"

          # CPU plugin settings
          set -g @powerkit_plugin_cpu_warning_threshold "70"
          set -g @powerkit_plugin_cpu_critical_threshold "90"

          # DateTime format (preset_1 = %Y-%m-%d %H:%M:%S)
          set -g @powerkit_plugin_datetime_format "preset_1"
        '';
      }
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
