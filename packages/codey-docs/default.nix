{
  lib,
  stdenv,
  fetchFromGitea,
  python3,
  python3Packages,
}:
stdenv.mkDerivation rec {
  pname = "codey-docs";
  version = "0.1.0";

  src = fetchFromGitea {
    domain = "forge.meskill.farm";
    owner = "iamruinous";
    repo = "codey-docs";
    rev = "v${version}";
    hash = ""; # Will be filled after first build attempt
  };

  nativeBuildInputs = [
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

  meta = with lib; {
    description = "Official documentation site for the Codey meta-persona";
    homepage = "https://codey.ruinous.ai";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
