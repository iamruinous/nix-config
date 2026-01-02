{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "eztunnel";
  version = "1.0.0";
  dontUnpack = true;

  propagatedBuildInputs = with pkgs; [
    openssh
  ];

  passthru.shellPath = "/bin/eztunnel";
  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin

    # Substitute executable paths in the shell script
    substitute ${./eztunnel.sh} $out/bin/eztunnel \
      --replace '@ssh@' '${pkgs.openssh}'

    chmod +x $out/bin/eztunnel
  '';

  installPhase = ''
    # No installation steps needed beyond what's done in buildPhase
    true
  '';

  meta = with pkgs.lib; {
    description = "Simple SSH local tunnel utility for accessing remote ports via localhost";
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "eztunnel";
    platforms = platforms.unix;
  };
}
