{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "nix-codesign-cert";
  version = "1.0.0";

  dontUnpack = true;

  nativeBuildInputs = [pkgs.makeWrapper];

  propagatedBuildInputs = [pkgs.openssl];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ${./nix-codesign-cert.sh} $out/bin/nix-codesign-cert
    chmod +x $out/bin/nix-codesign-cert

    wrapProgram $out/bin/nix-codesign-cert \
      --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.openssl]}

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Generate and install a self-signed code signing certificate for Nix packages";
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "nix-codesign-cert";
    platforms = platforms.darwin;
  };
}
