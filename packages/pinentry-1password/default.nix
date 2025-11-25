{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "pinentry-1password";
  version = "0.1.0";
  dontUnpack = true;

  propagatedBuildInputs = [
    pkgs.coreutils
  ];

  passthru.shellPath = "/bin/pinentry-1password";
  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin
    cp ${./pinentry-1password.sh} $out/bin/pinentry-1password
    chmod +x $out/bin/pinentry-1password
  '';

  installPhase = ''
    # No installation steps needed beyond what's done in buildPhase
    true
  '';

  meta = with pkgs.lib; {
    description = "1Password CLI pinentry program for GPG-Agent and rage";
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "pinentry-1password";
    platforms = platforms.unix;
  };
}
