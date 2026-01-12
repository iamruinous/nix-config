{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.kde
  ];

  programs.wezterm.enable = true;
  ruinous = {
    # allow use of 1password op-ssh-sign
    #git.signing.use1Password = true;

    # Enable rust-motd for system info on login
    rust-motd.enable = true;

    # Enable todoist
    # todoist.enable = true;

    # Enable vdirsyncer
    # vdirsyncer.enable = true;

    # ssh agent forwarding
    openssh.remote.forwarding.enable = true;
    openssh.tmux.attach.enable = true;

    # enable opencode with my preferred plugins
    ai-cli.opencode.enable = true;

    # tmuxp for declarative project sessions
    # Usage: tmuxp load nix-config
    tmuxp = {
      enable = true;

      sessions = {
        # Hub session - always running, use for session management
        hub = {
          windows = [
            {name = "shell"; focus = true;}
          ];
        };

        nix = {
          startDirectory = "~/Projects/github/iamruinous/nix-config";
          startCommands = ["direnv exec . true"];

          windows = [
            {
              name = "server";
              command = "opencode serve --hostname 127.0.0.1 --port 9500";
            }
            {
              name = "opencode";
              command = "sleep 2 && opencode attach http://localhost:9500";
              focus = true;
            }
            {
              name = "editor";
              command = "nvim .";
            }
            {name = "shell";}
          ];
        };

        n8n = {
          startDirectory = "~/Projects/farmforge/iamruinous/n8n-agent";
          startCommands = ["direnv exec . true"];

          windows = [
            {
              name = "server";
              command = "opencode serve --hostname 127.0.0.1 --port 9501";
            }
            {
              name = "opencode";
              command = "sleep 2 && opencode attach http://localhost:9501";
              focus = true;
            }
            {
              name = "editor";
              command = "nvim .";
            }
            {name = "shell";}
          ];
        };

        codey = {
          startDirectory = "~/Projects/farmforge/iamruinous/codey-system-agent";
          startCommands = ["direnv exec . true"];

          windows = [
            {
              name = "server";
              command = "opencode serve --hostname 127.0.0.1 --port 9503";
            }
            {
              name = "opencode";
              command = "sleep 2 && opencode attach http://localhost:9503";
              focus = true;
            }
            {
              name = "editor";
              command = "nvim .";
            }
            {name = "shell";}
          ];
        };

        dossiq = {
          startDirectory = "~/Projects/farmforge/iamruinous/dossiq-ai";
          startCommands = ["direnv exec . true"];

          windows = [
            {
              name = "server";
              command = "opencode serve --hostname 127.0.0.1 --port 9502";
            }
            {
              name = "opencode";
              command = "sleep 2 && opencode attach http://localhost:9502";
              focus = true;
            }
            {
              name = "editor";
              command = "nvim .";
            }
            {name = "shell";}
          ];
        };

        kimaki-discord = {
          startDirectory = "~/Projects/farmforge/iamruinous/kimaki-discord-voice-bot";
          startCommands = ["direnv exec . true"];

          windows = [
            {
              name = "server";
              command = "opencode serve --hostname 127.0.0.1 --port 9503";
            }
            {
              name = "opencode";
              command = "sleep 2 && opencode attach http://localhost:9503";
              focus = true;
            }
            {
              name = "editor";
              command = "nvim .";
            }
            {name = "shell";}
          ];
        };
      };
    };

    # Git config - use zenith-specific defaults for all repos
    git.default = {
      userEmail = "jade@ruinous.ai";
      signingKey = "/home/jmeskill/.ssh/id_codey_ed25519";
    };

    # KDE Plasma configuration
    kde.enable = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}
