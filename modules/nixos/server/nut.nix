{
  lib,
  config,
  flake,
  ...
}: {
  # Only configure UPS monitoring when enabled
  config = lib.mkIf config.power.ups.enable {
    power.ups = {
      mode = lib.mkDefault "netclient";
      upsmon = {
        enable = true;
        monitor."cyberpower-servers" = {
          system = lib.mkDefault "cyberpower-servers@nutify-servers.meskill.farm";
          user = "monuser";
          powerValue = 1;
          passwordFile = config.age.secrets.nut_client_password.file;
          type = "slave";
        };
      };
    };

    age.secrets.nut_client_password = {
      rekeyFile = flake + /files/configs/nut/password.age;
      mode = "600";
    };
  };
}
