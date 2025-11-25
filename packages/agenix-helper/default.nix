{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "agenix-helper";
  version = "0.1.0";
  dontUnpack = true;

  propagatedBuildInputs = [
    pkgs.rage
    pkgs.coreutils
  ];

  passthru.shellPath = "/bin/agenix-helper";
  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin

    # Substitute @rage@ with the actual rage path
    substitute ${./agenix-helper.sh} $out/bin/agenix-helper \
      --replace '@rage@' '${pkgs.rage}'

    chmod +x $out/bin/agenix-helper
  '';

  installPhase = ''
    # No installation steps needed beyond what's done in buildPhase
    true
  '';

  meta = with pkgs.lib; {
    description = "Helper utilities for working with agenix encrypted secrets";
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "agenix-helper";
    platforms = platforms.unix;
  };
}
