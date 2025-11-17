{
  config,
  pkgs,
  flake,
  ...
}: {
  home.packages = [
    pkgs.vdirsyncer
  ];

  # age.secrets.vdirsyncer_config = {
  #   rekeyFile = flake + /files/configs/vdirsyncer/config.age;
  #   path = "${config.home.homeDirectory}/.config/vdirsyncer/config";
  #   mode = "600";
  # };
}
