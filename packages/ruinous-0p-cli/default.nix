{pkgs, ...}:
let
  version = "0.1.0";
in
pkgs.buildGoModule {
  pname = "0p-cli";
  inherit version;

  src = ./.;

  vendorHash = null; # Will be populated by nix after first build attempt

  ldflags = [
    "-s"
    "-w"
    "-X forge.meskill.farm/ruinous/0p-cli/cmd.Version=${version}"
  ];

  nativeBuildInputs = with pkgs; [
    installShellFiles
  ];

  postInstall = ''
    installShellCompletion --cmd 0p \
      --bash <($out/bin/0p completion bash) \
      --fish <($out/bin/0p completion fish) \
      --zsh <($out/bin/0p completion zsh)
  '';

  meta = {
    description = "Op management CLI for isolated development sessions";
    homepage = "https://forge.meskill.farm/ruinous/0p-cli";
    license = pkgs.lib.licenses.mit;
    maintainers = with pkgs.lib.maintainers; [iamruinous];
    mainProgram = "0p";
  };
}
