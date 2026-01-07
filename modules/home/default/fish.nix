# ruinous.openssh.tmux.attach.enable = true;
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.ruinous.openssh.tmux.attach;
  tmuxAttachScript =
    if cfg.enable
    then ''
      if test -z "$TMUX" -a -n "$SSH_TTY"
        exec ${pkgs.tmux}/bin/tmux new-session -A -s shell
      end
    ''
    else "";
in {
  # fish shell configuration
  programs.fish = {
    enable = lib.mkDefault true;
    package = pkgs.fish;

    shellAbbrs = {
      dl = "curl --create-dirs -O --output-dir /tmp/";
      # Difftastic git aliases
      dft = "git dft";
      dlog = "git dlog";
      dshow = "git dshow";
      # glow + pager
      glp = "glow --pager";
      oc = "opencode run";
    };

    functions = {
      fish_user_key_bindings = ''
        bind \t complete-and-search
        bind \cw backward-kill-word

        # Alt+left
        bind \e\[1\;3D backward-kill-bigword
        bind \ek kill-whole-line
      '';

      l = {
        wraps = "xplr";
        body = "xplr $argv";
      };

      find = {
        wraps = "fd";
        body = "fd --follow --hidden $argv";
      };

      cat = {
        wraps = "bat";
        body = "bat $argv";
      };

      less = {
        wraps = "moor";
        body = "moor $argv";
      };

      top = {
        wraps = "btop";
        body = "btop $argv";
      };

      history = "builtin history --show-time='%h/%d - %H:%M:%S ' | moor";

      tree = {
        wraps = "eza";
        body = "eza --git --icons --tree $argv";
      };

      ps = {
        wraps = "procs";
        body = "procs $argv";
      };

      pkill = "command pkill -f -e $argv";

      df = {
        wraps = "duf";
        body = "duf --hide-fs tmpfs,vfat,devfs,devtmpfs $argv";
      };

      du = {
        wraps = "dust";
        body = "dust -b $argv";
      };

      cal = {
        wraps = "khal";
        body = "khal $argv";
      };

      call = "cal list";
      cala = "cal calendar";
      cali = "ikhal";

      randhex = ''hexdump -vn16 -e'4/4 "%08X" 1 "\n"' /dev/urandom'';
    };

    plugins = with pkgs.fishPlugins; [
      {
        name = "fzf-fish";
        src = fzf-fish.src;
      }
    ];

    interactiveShellInit = ''
      # Suppress the default "Welcome to fish" greeting
      set -g fish_greeting

      ${tmuxAttachScript}

      # Check SSH_AUTH_SOCK validity
      if ${pkgs.ssh-agent-check}/bin/ssh-agent-check
        set -gx SSH_AUTH_SOCK_INVALID 0
      else
        set -gx SSH_AUTH_SOCK_INVALID 1
        set_color red
        echo "⚠ SSH agent is not responding"
        set_color normal
      end

      if type -q ${pkgs.toilet}/bin/toilet; and type -q ${pkgs.lolcat}/bin/lolcat
        set -q TOILETMAXLENGTH || set TOILETMAXLENGTH 16
        set -q TOILETNAME || set TOILETNAME (hostname -s)
        if ! set -q TOILETFONT
          if test (string length "$TOILETNAME") -gt $TOILETMAXLENGTH
            set TOILETFONT "future"
          else
            set TOILETFONT "smblock"
          end
        end
        echo "$TOILETNAME" | ${pkgs.toilet}/bin/toilet -f "$TOILETFONT" | ${pkgs.lolcat}/bin/lolcat
      end

      # Display system info and fortune via rust-motd (if enabled)
      # Falls back to fortune only if rust-motd is not available
      if [ "$ITERM_PROFILE" != "Hotkey Window" ]
        if type -q ${pkgs.rust-motd}/bin/rust-motd
          echo ""
          ${pkgs.rust-motd}/bin/rust-motd 2>/dev/null
        else if type -q ${pkgs.fortune}/bin/fortune
          set_color brblack
          echo ""
          ${pkgs.fortune}/bin/fortune
          set_color normal; echo ""
        end
      end

      # TokyoNight Color Palette
      set -l foreground c0caf5
      set -l selection 283457
      set -l comment 565f89
      set -l red f7768e
      set -l orange ff9e64
      set -l yellow e0af68
      set -l green 9ece6a
      set -l purple 9d7cd8
      set -l cyan 7dcfff
      set -l pink bb9af7

      # Syntax Highlighting Colors
      set -g fish_color_normal $foreground
      set -g fish_color_command $cyan
      set -g fish_color_keyword $pink
      set -g fish_color_quote $yellow
      set -g fish_color_redirection $foreground
      set -g fish_color_end $orange
      set -g fish_color_error $red
      set -g fish_color_param $purple
      set -g fish_color_comment $comment
      set -g fish_color_selection --background=$selection
      set -g fish_color_search_match --background=$selection
      set -g fish_color_operator $green
      set -g fish_color_escape $pink
      set -g fish_color_autosuggestion $comment

      # Completion Pager Colors
      set -g fish_pager_color_progress $comment
      set -g fish_pager_color_prefix $cyan
      set -g fish_pager_color_completion $foreground
      set -g fish_pager_color_description $comment
      set -g fish_pager_color_selected_background --background=$selection
    '';
  };
}
