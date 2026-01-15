{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "codey-docs";
  version = "0.1.0";

  src = pkgs.fetchgit {
    url = "https://forge.meskill.farm/iamruinous/codey-docs.git";
    rev = "v${version}";
    hash = "sha256-CgrtGCcY3f9o8w6a7FXEFALEmzM91e0+d7lmmiXAwos=";
  };

  nativeBuildInputs = with pkgs; [
    python3
    python3Packages.mkdocs-material
  ];

  buildPhase = ''
    runHook preBuild
    
    # Build MkDocs site with strict mode
    mkdocs build --strict
    
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    
    # Copy built site to output
    mkdir -p $out
    cp -r site/* $out/
    
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Official documentation site for the Codey meta-persona";
    homepage = "https://codey.ruinous.ai";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
