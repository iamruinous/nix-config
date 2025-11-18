# ruinous.todoist.sync.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.todoist.sync;
in {
  config = mkIf cfg.enable (mkMerge [
    (mkIf pkgs.stdenv.isLinux {
      systemd.user.timers.todoist = {
        Unit = {
          Description = "sync todoist";
        };

        Timer = {
          OnBootSec = "1m";
          OnUnitInactiveSec = "15m";
          Unit = "todoist.service";
        };

        Install = {
          WantedBy = ["timers.target"];
        };
      };
      systemd.user.services.todoist = {
        Unit = {
          Description = "todoist auto sync";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.todoist}/bin/todoist sync";
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };
    })
    (mkIf pkgs.stdenv.isDarwin {
      launchd.agents.todoist = {
        enable = true;
        config = {
          ProgramArguments = ["${pkgs.todoist}/bin/todoist" "sync"];
          StartInterval = 900;
        };
      };
    })
    {
      home.packages = [
        pkgs.todoist
      ];

      age.secrets.todoist_config = {
        rekeyFile = flake + /files/configs/todoist/config.json.age;
        path = "${config.home.homeDirectory}/.config/todoist/config.json";
        mode = "600";
        symlink = false;
      };
    }
  ]);
}
