{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "forgejo-shell"; # this will be the name of the binary
  version = "0.0.1";
  dontUnpack = true;
  propagatedBuildInputs = [
    pkgs.docker
  ]; # Dependencies go here
  passthru.shellPath = "/bin/forgejo-shell";
  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin

    # Substitute @docker@ with the actual docker path
    substitute ${./forgejo-shell.sh} $out/bin/forgejo-shell \
      --replace '@docker@' '${pkgs.docker}'

    chmod +x $out/bin/forgejo-shell
  '';

  installPhase = ''
    # No installation steps needed beyond what's done in buildPhase for this simple example
    true
  '';

  meta = {
    platforms = ["x86_64-linux"];
    maintainers = [pkgs.lib.maintainers.jmeskill];
    mainProgram = "forgejo-shell";
  };
}
