{
  config,
  flake,
  ...
}: let
  wallpaper_dir = ../../../../files/wallpapers/nixos;
  workspace-wallpaper = "${wallpaper_dir}/pixel_sakura_static.png";
in {
  imports = [
    flake.homeModules.default
    flake.homeModules.kde
  ];

  ruinous = {
    # this system has a battery
    starship.battery.enable = true;
    tmux.powerkit.extraPlugins = ["battery"];

    # allow use of 1password op-ssh-sign
    git.signing.use1Password = true;

    # Enable rust-motd for system info on login
    rust-motd.enable = true;

    # Enable todoist
    todoist.enable = true;

    # Enable vdirsyncer
    vdirsyncer.enable = true;

    # ssh agent forwarding
    openssh.remote.forwarding.enable = true;

    # enable opencode with default configuration
    ruinage.enable = true;
    ruinage.assistants.opencode.enable = true;

    # KDE Plasma configuration with wallpaper
    kde = {
      enable = true;
      wallpaper = workspace-wallpaper;
    };
  };

  programs.wezterm.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}
