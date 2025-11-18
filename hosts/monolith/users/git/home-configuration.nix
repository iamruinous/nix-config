{flake, ...}: {
  imports = [
    flake.homeModules.common
  ];

  age.secrets.monolith_git_id_ed25519 = {
    rekeyFile = flake + /users/git/id_ed25519.age;
    path = "/home/git/.ssh/id_ed25519";
    mode = "600";
  };

  home.stateVersion = "25.05";
}
