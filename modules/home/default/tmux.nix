{
  lib,
  pkgs,
  ...
}: {
  # Tmux terminal multiplexer configuration
  programs.tmux = {
    enable = lib.mkDefault true;
    shell = "${pkgs.fish}/bin/fish";
    mouse = true;
    aggressiveResize = true;
    keyMode = "vi";
    baseIndex = 1;
    terminal = "tmux-256color";
    historyLimit = 100000;

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.copycat
      tmuxPlugins.pain-control
      tmuxPlugins.resurrect
      tmuxPlugins.sensible
      tmuxPlugins.yank
    ];

    extraConfig = ''
      set-option -g visual-activity off
      set-option -g visual-bell off
      set-option -g visual-silence off
      set-window-option -g monitor-activity on
      set-option -g bell-action none

      #set -g default-terminal "screen-256color"
      #set-option -ga terminal-overrides ",*256col*:RGB"
      set -as terminal-features ",xterm-256color:RGB"

      bind R \
        move-window -r\; \
        display-message "Windows reordered..."

      bind -n S-PPage copy-mode -u
      bind -T copy-mode S-PPage send -X page-up
      bind -T copy-mode S-NPage send -X page-down

      # theme
      set -g status "on"
      set -g status-right-length 150
      set -g status-justify left

      set -g status-left "#[fg=black,bg=blue,bold]#{?client_prefix,, tmux  #[fg=blue,bg=black,nobold,nounderscore,noitalics]}#[fg=black,bg=#41a6b5,bold]#{?client_prefix, tmux 󰘳 #[fg=#41a6b5 bg=black nobold nounderscore noitalics],}#[fg=blue,bg=default,nobold,noitalics,nounderscore] "

      set -g window-status-current-format "#[fg=#dddddd,bg=#1F2335]   #I #W  #{?window_last_flag,,} "
      set -g window-status-format "#[fg=brightwhite,bg=#1a1b26,nobold,noitalics,nounderscore]   #I #W #F  "

      set -g pane-border-style "fg=#3b4261"
      set -g pane-active-border-style "fg=#7aa2f7"

      set -g status-bg "#1a1b26"

      set -g status-right "#[bg=default,fg=#24283B]#[fg=white,bg=#24283B] %Y-%m-%d #[]❬ %H:%M #[fg=blue,bg=#24283B,nobold,nounderscore,noitalics]#[fg=black,bg=blue,bold]󰹑 #S "
      set -g window-status-separator ""
    '';
  };
}
