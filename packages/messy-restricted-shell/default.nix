{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "messy-restricted-shell"; # this will be the name of the binary
  version = "0.0.1";
  src = ./.;
  dontUnpack = true;
  nativeBuildInputs = [pkgs.makeWrapper];
  # passthru.shellPath = "/bin/messy-restricted-shell";
  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin
    cp $src/messy-restricted-shell.sh $out/bin/messy-restricted-shell
    wrapProgram $out/bin/messy-restricted-shell --prefix PATH : "${pkgs.lib.makeBinPath [pkgs.bash pkgs.docker]}"
  '';

  installPhase = ''
    # No installation steps needed beyond what's done in buildPhase for this simple example
    true
  '';

  meta = {
    platforms = ["x86_64-linux"];
    maintainers = [pkgs.lib.maintainers.jmeskill];
    mainProgram = "messy-restricted-shell";
  };
}
