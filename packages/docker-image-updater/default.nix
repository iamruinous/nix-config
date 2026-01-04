{pkgs, ...}:
pkgs.buildGoModule rec {
  pname = "docker-image-updater";
  version = "2.4.0";

  src = pkgs.lib.cleanSource ./.;

  vendorHash = "sha256-ZBYsRzPDE5xNASc8RCjS0dO2sQzUK4Lmgbi7pZBYS6Y=";

  subPackages = ["cmd/docker-image-updater"];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with pkgs.lib; {
    description = "Interactive TUI for checking Docker image updates in NixOS container configurations";
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "docker-image-updater";
    platforms = platforms.unix;
  };
}
