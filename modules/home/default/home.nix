{...}: {
  # Enable home-manager
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
# {
#   pkgs,
#   userConfig,
#   ...
# }: {
#   # Home-Manager configuration for the user's home environment
#   home = {
#     username = "${userConfig.name}";
#     homeDirectory =
#       if pkgs.stdenv.isDarwin
#       then "/Users/${userConfig.name}"
#       else "/home/${userConfig.name}";
#   };
# }

