{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.vdirsyncer-auto;
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
  ]);
}
