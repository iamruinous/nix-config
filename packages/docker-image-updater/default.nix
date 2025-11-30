{pkgs, ...}:
pkgs.buildGoModule rec {
  pname = "docker-image-updater";
  version = "2.0.0";

  # Use local source
  src = ./.;

  vendorHash = "sha256-vYwK/UU5tzdZJ21FtyA0k/Zy0tpD8BU5w7mATUbS/P4=";

  # Only build the main command
  subPackages = ["cmd/docker-image-updater"];

  # Disable CGO for static binary
  env.CGO_ENABLED = 0;

  # Build flags to strip debug info and embed version
  ldflags = [
    "-s" # Strip symbol table
    "-w" # Strip DWARF
    "-X main.version=${version}"
  ];

  # Wrap with runtime dependencies (skopeo must be available)
  nativeBuildInputs = [pkgs.makeWrapper];

  postInstall = ''
    wrapProgram $out/bin/docker-image-updater \
      --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.skopeo]}
  '';

  meta = with pkgs.lib; {
    description = "Interactive TUI for checking Docker image updates in NixOS container configurations";
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "docker-image-updater";
    platforms = platforms.unix;
  };
}
