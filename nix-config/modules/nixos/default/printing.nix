{
  lib,
  config,
  ...
}: let
  cfg = config.services.printing;
in {
  config = lib.mkIf cfg.discoverable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };

    fonts.enableDefaultPackages = true;

    services.printing = {
      listenAddresses = ["*:631"];
      allowFrom = ["all"];
      browsing = true;
      defaultShared = true;
      openFirewall = true;
    };
  };
}
