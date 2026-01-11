{flake, ...}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.kde
  ];

  programs.wezterm.enable = true;
  ruinous = {
    # allow use of 1password op-ssh-sign
    #git.signing.use1Password = true;

    # Enable rust-motd for system info on login
    rust-motd.enable = true;

    # Enable todoist
    # todoist.enable = true;

    # Enable vdirsyncer
    # vdirsyncer.enable = true;

    # ssh agent forwarding
    openssh.remote.forwarding.enable = true;
    openssh.tmux.attach.enable = true;

    # enable opencode with my preferred plugins
    ai-cli.opencode.enable = true;

    # Git config - use zenith-specific defaults for all repos
    git.default = {
      userEmail = "jade@ruinous.ai";
      signingKey = "/home/jmeskill/.ssh/id_codey_ed25519";
    };

    # KDE Plasma configuration
    kde.enable = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}
