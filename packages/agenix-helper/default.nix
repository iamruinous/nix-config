{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "agenix-helper";
  version = "0.1.0";
  dontUnpack = true;

  propagatedBuildInputs = [
    pkgs.rage
    pkgs.coreutils
    pkgs.gum
  ];

  passthru.shellPath = "/bin/agenix-helper";
  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin

    substitute ${./agenix-helper.sh} $out/bin/agenix-helper \
      --replace '@rage@' '${pkgs.rage}' \
      --replace '@gum@' '${pkgs.gum}'

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
