{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "ruinagents-docs";
  version = "0.1.0";

  src = pkgs.fetchgit {
    url = "https://forge.meskill.farm/iamruinous/ruinagents.git";
    rev = "v${version}";
    hash = "sha256-ZDFakt+V/7xImUN7t6mmRJ85SjAFDFVlWUbPwSEdY4s=";
  };

  nativeBuildInputs = with pkgs; [
    python3
    python3Packages.mkdocs-material
  ];

  buildPhase = ''
    runHook preBuild
    
    # Build MkDocs site (strict mode disabled due to WIP docs)
    mkdocs build
    
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
    description = "Official documentation site for ruinous.ai agents";
    homepage = "https://agents.ruinous.ai";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
