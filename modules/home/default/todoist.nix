{
  config,
  pkgs,
  flake,
  ...
}: {
  home.packages = [
    pkgs.todoist
  ];

  # age.secrets.todoist_config = {
  #   rekeyFile = flake + /files/configs/todoist/config.json.age;
  #   path = "${config.home.homeDirectory}/.config/todoist/config.json";
  #   mode = "600";
  #   symlink = false;
  # };
}
