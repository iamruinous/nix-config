{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "messy-docs";
  version = "0.1.0";

  # NOTE: Repository must be public for fetchgit to work
  src = pkgs.fetchgit {
    url = "https://forge.meskill.farm/iamruinous/messy-docs.git";
    rev = "v${version}";
    hash = "sha256-5kQa6QmEU45Ej+xbVKw6vRiW04KCIESX6sKOB8W4y6E=";
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
    description = "Documentation site for MESSY - The Meskill Family Personal Assistant";
    homepage = "https://messy.ruinous.ai";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
