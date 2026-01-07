{flake, ...}: let
  # wallpaper_dir = ../../../../files/wallpapers/nixos;
  # workspace-wallpaper = "${wallpaper_dir}/pixel_sakura_static.png";
in {
  imports = [
    flake.inputs.plasma-manager.homeModules.plasma-manager
    flake.homeModules.default
  ];

  # Enable todoist
  # ruinous.todoist.enable = true;

  # Enable vdirsyncer
  # ruinous.vdirsyncer.enable = true;

  ruinous.git.signing.use1Password = true;
  ruinous.rust-motd.enable = true;
  programs.wezterm.enable = true;
  ruinous.openssh.remote.forwarding.enable = true;
  ruinous.openssh.tmux.attach.enable = true;

  programs.plasma = {
    enable = true;
    # kscreenlocker.appearance.wallpaper = "${workspace-wallpaper}";
    workspace = {
      # wallpaper = "${workspace-wallpaper}";
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
        description = "Google Chrome nix";
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
            value = "Desktop 1";
          };
        };
      }
      {
        description = "Obsidian nix";
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
            value = "Desktop 2";
          };
        };
      }
      {
        description = "WezTerm nix";
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
            value = "Desktop 3";
          };
        };
      }
      {
        description = "Todoist nix";
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
            value = "Desktop 4";
          };
        };
      }
      {
        description = "Steam nix";
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
            value = "Desktop 5";
          };
        };
      }
      {
        description = "Glance nix";
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
            value = "Desktop 6";
          };
        };
      }
      {
        description = "Gemini nix";
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
            value = "Desktop 6";
          };
        };
      }
    ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}
