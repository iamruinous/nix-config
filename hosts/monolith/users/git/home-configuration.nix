{flake, ...}: {
  imports = [
    flake.homeModules.common
  ];

  home.file.".ssh/id_ed25519.pub".source = flake + /users/git/id_ed25519.pub;

  # Install git via home-manager module
  programs.git = {
    enable = true;
    settings = {
      user.name = "Farmforge Git";
      user.email = "git@meskill.farm";
      user.signingkey = "/home/git/.ssh/id_ed25519.pub";
      commit.gpgsign = true;
      gpg.format = "ssh";
    };
  };

  home.stateVersion = "26.05";
}
