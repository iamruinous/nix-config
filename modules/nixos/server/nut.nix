{
  lib,
  config,
  flake,
  ...
}: {
  power.ups = {
    mode = lib.mkDefault "netclient";
    upsmon = {
      enable = true;
      monitor = {
        system = lib.mkDefault "cyberpower-servers@nutify-servers.meskill.farm";
        user = "monuser";
        powerValue = 1;
        passwordFile = config.age.secrets.nut_client_password;
        type = "slave";
      };
    };
  };

  age.secrets.nut_client_password = {
    rekeyFile = flake + /files/configs/nut/password.age;
    mode = "600";
  };
}
