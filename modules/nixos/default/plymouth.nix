# boot.plymouth.enable = true;
{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.boot.plymouth;
in {
  config = lib.mkIf cfg.enable {
    boot = {
      # plymouth for fancy boot splash
      plymouth = {
        theme = lib.mkDefault "motion";
        themePackages = with pkgs; [
          (adi1090x-plymouth-themes.override {
            selected_themes = ["motion"];
          })
        ];
      };
      # enable silent boot
      consoleLogLevel = 0;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
      loader.timeout = 3;
    };
  };
}
