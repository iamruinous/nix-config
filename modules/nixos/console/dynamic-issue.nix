# Dynamic /etc/issue generator
# Displays system info at the login prompt (before login)
{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.ruinous.dynamicIssue;

  # Script to generate /etc/issue with system info
  # Uses substitute to replace @placeholder@ with actual package paths
  generateIssue = pkgs.substitute {
    src = ./generate-issue.sh;
    isExecutable = true;
    substitutions = [
      "--replace-fail"
      "#!/usr/bin/env bash"
      "#!${pkgs.bash}/bin/bash"
      "--replace-fail"
      "@hostname@"
      "${pkgs.hostname}"
      "--replace-fail"
      "@coreutils@"
      "${pkgs.coreutils}"
      "--replace-fail"
      "@iproute2@"
      "${pkgs.iproute2}"
      "--replace-fail"
      "@gawk@"
      "${pkgs.gawk}"
      "--replace-fail"
      "@procps@"
      "${pkgs.procps}"
    ];
  };
in {
  options.ruinous.dynamicIssue = {
    enable =
      lib.mkEnableOption "dynamic /etc/issue with system info"
      // {
        default = true;
      };

    refreshInterval = lib.mkOption {
      type = lib.types.str;
      default = "*:0/5"; # Every 5 minutes
      description = "How often to regenerate the issue file (systemd OnCalendar format)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Don't let NixOS manage /etc/issue
    environment.etc."issue".enable = false;

    # Service to generate the issue file
    systemd.services.generate-issue = {
      description = "Generate dynamic /etc/issue";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = generateIssue;
        RemainAfterExit = false;
      };
    };

    # Timer to refresh periodically
    systemd.timers.generate-issue = {
      description = "Refresh /etc/issue periodically";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.refreshInterval;
        OnBootSec = "10s";
        Persistent = true;
      };
    };
  };
}
