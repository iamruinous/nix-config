# ruinous.vdirsyncer.sync.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.vdirsyncer.sync;
  khal_config = ../../../files/configs/khal/config;
in {
  config = mkIf cfg.enable (mkMerge [
    (mkIf pkgs.stdenv.isLinux {
      systemd.user.timers.vdirsyncer = {
        Unit = {
          Description = "sync vdirsyncer";
        };

        Timer = {
          OnBootSec = "1m";
          OnUnitInactiveSec = "15m";
          Unit = "vdirsyncer.service";
        };

        Install = {
          WantedBy = ["timers.target"];
        };
      };
      systemd.user.services.vdirsyncer = {
        Unit = {
          Description = "vdirsyncer auto sync";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };
    })
    (mkIf pkgs.stdenv.isDarwin {
      launchd.agents.vdirsyncer = {
        enable = true;
        config = {
          ProgramArguments = ["${pkgs.vdirsyncer}/bin/vdirsyncer" "sync"];
          StartInterval = 900;
        };
      };
    })
    {
      home.packages = [
        pkgs.vdirsyncer
      ];

      age.secrets.vdirsyncer_config = {
        rekeyFile = flake + /files/configs/vdirsyncer/config.age;
        path = "${config.home.homeDirectory}/.config/vdirsyncer/config";
        mode = "600";
      };

      # Install khal via home-manager module
      programs.khal = {
        enable = lib.mkDefault true;
      };

      xdg.configFile."khal/config".source = "${khal_config}";
    }
  ]);
}
