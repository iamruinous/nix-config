{flake, ...}: {
  imports = [
    flake.homeModules.default
  ];

  ruinous.rust-motd.enable = true;

  # Git configuration for automation via ruinous.git module
  # Using codey-bot identity for Forgejo commits
  ruinous.git = {
    default = {
      userName = "Codey Bot";
      userEmail = "codey-bot@ruinous.ai";
      # SSH key at ~/.ssh/id_ed25519 (persisted via impermanence)
      signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3NzNxYBcnQuIfFau3nAS+2D3ea1kMD1h+cVw0icuEZ builder@builder-tty";
    };
    # Don't use 1Password on this VM - use local SSH key
    signing.use1Password = false;
    # Add codey-bot to allowed signers
    allowedSigners = [
      {
        email = "codey-bot@ruinous.ai";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3NzNxYBcnQuIfFau3nAS+2D3ea1kMD1h+cVw0icuEZ builder@builder-tty";
      }
    ];
  };

  programs.git.extraConfig = {
    push.autoSetupRemote = true;
  };

  # gh CLI for creating PRs
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };

  home.stateVersion = "26.05";
}
