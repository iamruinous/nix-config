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

    cat > $out/bin/forgejo-shell << EOF
    #!/bin/sh
    ${pkgs.docker}/bin/docker exec -i --env SSH_ORIGINAL_COMMAND="\$SSH_ORIGINAL_COMMAND" forgejo su git -c "\$@"
    EOF

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
