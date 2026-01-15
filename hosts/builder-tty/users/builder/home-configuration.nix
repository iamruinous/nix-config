{flake, lib, pkgs, ...}: {
  imports = [
    flake.homeModules.default
  ];

  ruinous.rust-motd.enable = true;

  # Git configuration for automation via ruinous.git module
  ruinous.git = {
    default = {
      userName = "Builder Bot";
      userEmail = "builder@ruinous.ai";
      # Signing key will be configured manually after deployment
      # For GPG: set signingKey to key ID after importing
    };
    # Don't use 1Password on this VM
    signing.use1Password = false;
  };

  # Override signing to use GPG instead of SSH
  # (builder will have a GPG key for signed commits)
  programs.git.signing = {
    format = lib.mkForce "openpgp";
    signer = lib.mkForce "${pkgs.gnupg}/bin/gpg";
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
