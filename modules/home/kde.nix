# KDE Plasma configuration module for home-manager
# Shared configuration for KDE desktop environments
{
  lib,
  config,
  flake,
  ...
}: let
  cfg = config.ruinous.kde;
in {
  imports = [
    flake.inputs.plasma-manager.homeModules.plasma-manager
  ];

  options.ruinous.kde = {
    enable = lib.mkEnableOption "KDE Plasma configuration";

    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to wallpaper image";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.plasma = {
      enable = true;

      kscreenlocker.appearance.wallpaper = lib.mkIf (cfg.wallpaper != null) cfg.wallpaper;

      workspace = {
        wallpaper = lib.mkIf (cfg.wallpaper != null) cfg.wallpaper;
        lookAndFeel = "org.kde.breeze.desktop";
        colorScheme = "BreezeDark";
        cursor.theme = "breeze_cursors";
      };

      kwin = {
        virtualDesktops = {
          rows = 1;
          number = 6;
        };
        tiling = {
          padding = 4;
          layout = {
            id = "c8a4a66d-bbca-5e7f-8a37-ce3b4a705568";
            tiles = {
              layoutDirection = "horizontal";
              tiles = [
                {width = 0.25;}
                {width = 0.5;}
                {width = 0.25;}
              ];
            };
          };
        };
      };

      # KWin configFile for settings not covered by structured options
      configFile = {
        # Krohnkite plugin (set to false to disable)
        "kwinrc"."Plugins"."krohnkiteEnabled" = true;
        "kwinrc"."Plugins"."desktopchangeosdEnabled" = false;

        # Window behavior
        "kwinrc"."Windows"."FocusPolicy" = "FocusFollowsMouse";
        "kwinrc"."Windows"."Placement" = "Maximizing";

        # TabBox (Alt+Tab behavior)
        "kwinrc"."TabBox"."ApplicationsMode" = 1;
        "kwinrc"."TabBox"."DesktopMode" = 2;
        "kwinrc"."TabBox"."HighlightWindows" = false;
        "kwinrc"."TabBox"."MinimizedMode" = 1;
        "kwinrc"."TabBox"."OrderMinimizedMode" = 1;
        "kwinrc"."TabBox"."ShowDesktopMode" = 1;

        # Xwayland scaling
        "kwinrc"."Xwayland"."Scale" = 1.7;

        # kwinrc - Krohnkite script settings
        "kwinrc"."Script-krohnkite"."screenGapBottom" = 6;
        "kwinrc"."Script-krohnkite"."screenGapLeft" = 6;
        "kwinrc"."Script-krohnkite"."screenGapRight" = 6;
        "kwinrc"."Script-krohnkite"."screenGapTop" = 6;

        # Krohnkite shortcuts (in kglobalshortcutsrc under [kwin] section)
        # Format: "shortcut,default,description"
        "kglobalshortcutsrc"."kwin"."KrohnkiteFocusDown" = "Meta+J,none,Krohnkite: Focus Down";
        "kglobalshortcutsrc"."kwin"."KrohnkiteFocusLeft" = "Meta+H,none,Krohnkite: Focus Left";
        "kglobalshortcutsrc"."kwin"."KrohnkiteFocusUp" = "Meta+K,none,Krohnkite: Focus Up";
        "kglobalshortcutsrc"."kwin"."KrohnkiteFocusPrev" = "Meta+\\\\,,none,Krohnkite: Focus Previous";
        "kglobalshortcutsrc"."kwin"."KrohnkiteShiftDown" = "Meta+Shift+J,none,Krohnkite: Move Down/Next";
        "kglobalshortcutsrc"."kwin"."KrohnkiteShiftLeft" = "Meta+Shift+H,none,Krohnkite: Move Left";
        "kglobalshortcutsrc"."kwin"."KrohnkiteShiftRight" = "Meta+Shift+L,none,Krohnkite: Move Right";
        "kglobalshortcutsrc"."kwin"."KrohnkiteShiftUp" = "Meta+Shift+K,none,Krohnkite: Move Up/Prev";
        "kglobalshortcutsrc"."kwin"."KrohnkiteToggleFloat" = "Meta+F,none,Krohnkite: Toggle Float";
        "kglobalshortcutsrc"."kwin"."KrohnkiteFloatAll" = "Meta+Shift+F,none,Krohnkite: Toggle Float All";
        "kglobalshortcutsrc"."kwin"."KrohnkiteMonocleLayout" = "Meta+M,none,Krohnkite: Monocle Layout";
        "kglobalshortcutsrc"."kwin"."KrohnkiteSetMaster" = "Meta+Return,none,Krohnkite: Set master";
        "kglobalshortcutsrc"."kwin"."KrohnkiteNextLayout" = "Meta+\\\\\\\\,none,Krohnkite: Next Layout";
        "kglobalshortcutsrc"."kwin"."KrohnkitePreviousLayout" = "Meta+|,none,Krohnkite: Previous Layout";
        "kglobalshortcutsrc"."kwin"."KrohnkiteIncrease" = "Meta+I,none,Krohnkite: Increase";
        "kglobalshortcutsrc"."kwin"."KrohnkiteGrowHeight" = "Meta+Ctrl+J,none,Krohnkite: Grow Height";
        "kglobalshortcutsrc"."kwin"."KrohnkiteShrinkHeight" = "Meta+Ctrl+K,none,Krohnkite: Shrink Height";
        "kglobalshortcutsrc"."kwin"."KrohnkiteShrinkWidth" = "Meta+Ctrl+H,none,Krohnkite: Shrink Width";
        "kglobalshortcutsrc"."kwin"."KrohnkitegrowWidth" = "Meta+Ctrl+L,none,Krohnkite: Grow Width";

        # Built-in KWin tile editor shortcut
        "kglobalshortcutsrc"."kwin"."Edit Tiles" = "Meta+T,Meta+T,Toggle Tiles Editor";
      };

      window-rules = [
        {
          description = "Google Chrome";
          match = {
            window-class = {
              type = "exact";
              value = "google-chrome";
              match-whole = false;
            };
          };
          apply = {
            desktops = {
              apply = "initially";
              value = "Desktop_1";
            };
          };
        }
        {
          description = "Obsidian";
          match = {
            window-class = {
              type = "exact";
              value = "obsidian";
              match-whole = false;
            };
          };
          apply = {
            desktops = {
              apply = "initially";
              value = "Desktop_2";
            };
          };
        }
        {
          description = "WezTerm";
          match = {
            window-class = {
              type = "exact";
              value = "org.wezfurlong.wezterm";
              match-whole = false;
            };
          };
          apply = {
            desktops = {
              apply = "initially";
              value = "Desktop_3";
            };
          };
        }
        {
          description = "Discord";
          match = {
            window-class = {
              type = "exact";
              value = "discord";
              match-whole = false;
            };
          };
          apply = {
            desktops = {
              apply = "initially";
              value = "Desktop_4";
            };
          };
        }
        {
          description = "Todoist";
          match = {
            window-class = {
              type = "exact";
              value = "Todoist";
              match-whole = false;
            };
          };
          apply = {
            desktops = {
              apply = "initially";
              value = "Desktop_4";
            };
          };
        }
        {
          description = "Steam";
          match = {
            window-class = {
              type = "exact";
              value = "steam";
              match-whole = false;
            };
          };
          apply = {
            desktops = {
              apply = "initially";
              value = "Desktop_5";
            };
          };
        }
        {
          description = "Glance";
          match = {
            window-class = {
              type = "exact";
              value = "chrome-ljlamgbgefobjkjkepgbmbebcoaheadj-Default";
              match-whole = false;
            };
          };
          apply = {
            desktops = {
              apply = "initially";
              value = "Desktop_6";
            };
          };
        }
        {
          description = "Gemini";
          match = {
            window-class = {
              type = "exact";
              value = "chrome-gdfaincndogidkdcdkhapmbffkckdkhn-Default";
              match-whole = false;
            };
          };
          apply = {
            desktops = {
              apply = "initially";
              value = "Desktop_6";
            };
          };
        }
      ];
    };
  };
}
