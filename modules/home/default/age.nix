{
  config,
  flake,
  ...
}: {
  imports = [
    flake.inputs.agenix.homeManagerModules.default
  ];

  age.identityPaths = ["${config.home.homeDirectory}/.ssh/id_dotfiles_ed25519"];
}
