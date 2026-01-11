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
