# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  pkgs,
  config,
  ...
}: {
  networking.firewall.allowedTCPPorts = [8433 8915];

  hardware.rtl-sdr.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    rtl_433
  ];

  systemd.services.rtl433 = {
    description = "rtl433 service";
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.rtl_433}/bin/rtl_433 -c ${config.age.secrets.monolith_rtl433_conf.path}";
      Restart = "always";
      RestartSteps = 5;
      RestartMaxDelaySec = "10s";
    };
  };

  systemd.services.rtl915 = {
    description = "rtl915 service";
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.rtl_433}/bin/rtl_433 -c ${config.age.secrets.monolith_rtl915_conf.path}";
      Restart = "always";
      RestartSteps = 5;
      RestartMaxDelaySec = "10s";
    };
  };

  age.secrets.monolith_rtl433_conf = {
    file = ./files/rtl_433/rtl_433.conf.age;
    mode = "600";
  };
  age.secrets.monolith_rtl915_conf = {
    file = ./files/rtl_433/rtl_915.conf.age;
    mode = "600";
  };
}
