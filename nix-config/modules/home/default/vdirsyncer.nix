{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    pkgs.vdirsyncer
  ];

  age.secrets.vdirsyncer_config = {
    file = ../../../files/configs/vdirsyncer/config.age;
    path = "${config.home.homeDirectory}/.config/vdirsyncer/config";
    mode = "600";
  };
}
