{
  lib,
  inputs,
  ...
}: let
  wallpaper_dir = ../../files/wallpapers/nixos;
  space-wallpaper = "${wallpaper_dir}/space1-wallpaper.jpg";
in {
  imports = [
    inputs.walker.homeManagerModules.default
  ];
  services.mako.enable = true;
  # home.packages = with pkgs; [
  #   anyrun
  # ];

  wayland.windowManager.hyprland = {
    enable = lib.mkDefault true;
    systemd.variables = ["--all"];
    settings = {
      general = {
        allow_tearing = false;
        border_size = 1;
        "col.active_border" = "rgb(b7bdf8)";
        gaps_in = 3;
        gaps_out = 3;
        layout = "master";
      };
      opengl = {
        nvidia_anti_flicker = false;
      };

      # Window decorations settings
      decoration = {
        rounding = 8;
        blur = {
          enabled = false;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = false;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };
      misc = {
        force_default_wallpaper = 0; # Set to 0 to disable the anime mascot wallpapers
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        vrr = 2;
      };
      gestures = {
        workspace_swipe = "on";
      };
      dwindle = {
        pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true; # you probably want this
      };
      "$mainMod" = "SUPER";
      exec-once = [
        "hyprpaper"
        "hypridle"
        "hyprswitch init --show-title --size-factor 5.5 --workspaces-per-row 5"
      ];
      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
      bind =
        [
          "$mainMod, G, exec, google-chrome-stable"
          ", Print, exec, grimblast copy area"
          "$mainMod SHIFT, Return, exec, wezterm"
          "$mainMod SHIFT, F, exec, nautilus"
          "$mainMod SHIFT, T, exec, telegram-desktop"
          "CTRL ALT, P, exec, gnome-pomodoro --start-stop"
          "$mainMod, Return, layoutmsg, swapwithmaster"
          "$mainMod, O, layoutmsg, orientationcycle"
          "$mainMod, Q, killactive,"
          "CTRL ALT, Q, exit"
          "$mainMod, F, togglefloating"
          "$mainMod, M, fullscreen"
          "$mainMod SHIFT, M, movetoworkspacesilent, special"
          "$mainMod SHIFT, P, togglespecialworkspace"
          "$mainMod SHIFT, C, exec, hyprpicker -a"

          # Move focus with mainMod + arrow keys
          "$mainMod, l, movefocus, l"
          "$mainMod, h, movefocus, r"
          "$mainMod, k, movefocus, u"
          "$mainMod, j, movefocus, d"

          # Resize windows
          "$mainMod SHIFT, left, resizeactive, -50 0"
          "$mainMod SHIFT, right, resizeactive, 50 0"
          "$mainMod SHIFT, up, resizeactive, 0 -50"
          "$mainMod SHIFT, down, resizeactive, 0 50"

          # Scroll through existing workspaces with mainMod + scroll
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"

          # Application menu
          "$mainMod, A, exec, wofi --show drun --allow-images"

          # Center focused window
          "CTRL ALT, C, centerwindow"

          # Clipboard
          "ALT SHIFT, V, exec, cliphist list | wofi --show dmenu | cliphist decode | wl-copy"

          # Ulauncher
          "CTRL, Space, exec, walker"

          # Screenshot area
          "$mainMod SHIFT, S, exec, grim -g \"$(slurp)\" - | swappy -f -"

          # Screenshot entire screen
          "$mainMod CTRL, S, exec, grim - | swappy -f -"

          # Screen recording
          "$mainMod SHIFT, R, exec, $HOME/.local/bin/screen-recorder"

          # OCR
          "ALT SHIFT, 2, exec, $HOME/.local/bin/ocr"

          # Lock screen
          "CTRL ALT, L, exec, hyprlock"

          # Adjust brightness
          ", XF86MonBrightnessUp, exec, brightnessctl set +10%"
          ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"

          # Open notifications
          "$mainMod, V, exec, swaync-client -t -sw"

          # Adjust  volume
          ", XF86AudioRaiseVolume, exec, pamixer --increase 10"
          ", XF86AudioLowerVolume, exec, pamixer --decrease 10"
          ", XF86AudioMute, exec, pamixer --toggle-mute"
          ", XF86AudioMicMute, exec, pamixer --default-source --toggle-mute"

          # Adjust mic sensitivity
          "SHIFT, XF86AudioRaiseVolume, exec, pamixer --increase 10 --default-source"
          "SHIFT, XF86AudioLowerVolume, exec, pamixer --decrease 10 --default-source"

          # Adjust keyboard backlight
          "SHIFT, XF86MonBrightnessUp, exec, brightnessctl -d tpacpi::kbd_backlight set +33%"
          "SHIFT, XF86MonBrightnessDown, exec, brightnessctl -d tpacpi::kbd_backlight set 33%-"

          # Switch applications
          "$mainMod, TAB, exec, hyprswitch gui --mod-key super --key tab --max-switch-offset 9 --hide-active-window-border"
        ]
        ++ (
          # workspaces
          # binds $mainMod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList
            (
              i: let
                ws = i + 1;
              in [
                "$mainMod, code:1${toString i}, workspace, ${toString ws}"
                "$mainMod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9)
        );
      windowrule = [
        # Center specific windows
        "center 1, ^(.blueman-manager-wrapped)$"
        "center 1, ^(gnome-calculator|org\.gnome\.Calculator)$"
        "center 1, ^(nm-connection-editor)$"
        "center 1, ^(org.pulseaudio.pavucontrol)$"

        # Float specific windows
        "float, ^(.blueman-manager-wrapped)$"
        "float, ^(gnome-calculator|org\.gnome\.Calculator)$"
        "float, ^(nm-connection-editor)$"
        "float, ^(org.pulseaudio.pavucontrol)$"
        "float, ^(walker)$"

        # Remove border for specific applications
        "noborder, ^(walker)$"

        # Set size for specific windows
        "size 50%, ^(.blueman-manager-wrapped)$"
        "size 50%, ^(nm-connection-editor)$"
        "size 50%, ^(org.pulseaudio.pavucontrol)$"

        # Keep focus on specific windows when they open
        "stayfocused, ^(.blueman-manager-wrapped)$"
        "stayfocused, ^(gnome-calculator|org\.gnome\.Calculator)$"
        "stayfocused, ^(org.pulseaudio.pavucontrol)$"
        "stayfocused, ^(swappy)$"
        "stayfocused, ^(walker)$"

        # Assign applications to specific workspaces
        "workspace 1, ^(google-chrome)$"
        "workspace 2, ^(org\.wezfurlong\.wezterm)$"
        "workspace 3, ^(org\.telegram\.desktop)$"
        "workspace 4, ^(com\.obsproject\.Studio)$"
        "workspace 4, ^(steam)$"
        "workspace 5 silent, ^(zoom)$"
        "workspace special, ^(gnome-pomodoro)$"
      ];
      windowrulev2 = [
        "workspace special silent, title:^(.*is sharing (your screen|a window)\.)$"
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      background = {
        monitor = "";
        path = "${space-wallpaper}";
        blur_passes = 3;
        contrast = 0.8916;
        brightness = 0.8172;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };

      general = {
        no_fade_in = false;
        grace = 0;
        disable_loading_bar = true;
      };

      input-field = [
        # DP-1 Config
        {
          monitor = "DP-1";
          size = "250, 60";
          outline_thickness = 2;
          dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(0, 0, 0, 0.5)";
          font_color = "rgb(200, 200, 200)";
          fade_on_empty = false;
          capslock_color = -1;
          placeholder_text = "<i><span foreground=\"##e6e9ef\">Password</span></i>";
          fail_text = "<i>\$FAIL <b>(\$ATTEMPTS)</b></i>";
          hide_input = false;
          position = "0, -60";
          halign = "center";
          valign = "center";
        }
        # eDP-1 Config
        {
          monitor = "eDP-1";
          size = "500, 120";
          outline_thickness = 2;
          dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
          dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
          dots_center = true;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(0, 0, 0, 0.5)";
          font_color = "rgb(200, 200, 200)";
          fade_on_empty = false;
          capslock_color = -1;
          placeholder_text = "<i><span foreground=\"##e6e9ef\">Password</span></i>";
          fail_text = "<i>\$FAIL <b>(\$ATTEMPTS)</b></i>";
          hide_input = false;
          position = "0, -120";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        # Date
        {
          monitor = "DP-1";
          text = "cmd[update:1000] echo \"<span>\$(date '+%A, %d %B')</span>\"";
          color = "rgba(255, 255, 255, 0.8)";
          font_size = 30;
          font_family = "BigBlueTermPlus Nerd Font";
          position = "0, -200";
          halign = "center";
          valign = "top";
        }
        # Time
        {
          monitor = "DP-1";
          text = "cmd[update:1000] echo \"<span>\$(date '+%H:%M')</span>\"";
          color = "rgba(255, 255, 255, 0.8)";
          font_size = 240;
          font_family = "BigBlueTerm437 Nerd Font";
          position = "0, -220";
          halign = "center";
          valign = "top";
        }
        # Keyboard layout
        {
          monitor = "DP-1";
          text = "\$LAYOUT";
          color = "rgba(255, 255, 255, 0.9)";
          font_size = 20;
          font_family = "BigBlueTermPlus Nerd Font";
          position = "0, -180";
          halign = "center";
          valign = "center";
        }
        # Date
        {
          monitor = "eDP-1";
          text = "cmd[update:1000] echo \"<span>\$(date '+%A, %d %B')</span>\"";
          color = "rgba(255, 255, 255, 0.8)";
          font_size = 30;
          font_family = "BigBlueTermPlus Nerd Font";
          position = "0, -400";
          halign = "center";
          valign = "top";
        }
        # Time
        {
          monitor = "eDP-1";
          text = "cmd[update:1000] echo \"<span>\$(date '+%H:%M')</span>\"";
          color = "rgba(255, 255, 255, 0.8)";
          font_size = 240;
          font_family = "BigBlueTerm437 Nerd Font";
          position = "0, -420";
          halign = "center";
          valign = "top";
        }
        # Keyboard layout
        {
          monitor = "eDP-1";
          text = "\$LAYOUT";
          color = "rgba(255, 255, 255, 0.9)";
          font_size = 20;
          font_family = "BigBlueTermPlus Nerd Font";
          position = "0, -230";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  services.hyprpaper = {
    enable = true;

    settings = {
      ipc = "on";
      splash = false;
      preload = "${wallpaper_dir}/space1-wallpaper.jpg";
      wallpaper = [
        "eDP-1,${wallpaper_dir}/space1-wallpaper.jpg"
        "DP-1,${wallpaper_dir}/space1-wallpaper.jpg"
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
    };
  };

  programs.walker = {
    enable = true;
    runAsService = true;

    # All options from the config.json can be used here.
    config = {
      search.placeholder = "Example";
      ui.fullscreen = true;
      list = {
        height = 200;
      };
      websearch.prefix = "?";
      switcher.prefix = "/";
    };
  };
}
