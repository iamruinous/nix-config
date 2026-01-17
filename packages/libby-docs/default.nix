{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "libby-docs";
  version = "0.1.0";

  src = pkgs.fetchgit {
    url = "https://forge.meskill.farm/iamruinous/libby-docs.git";
    rev = "v${version}";
    # TODO: Update hash after v0.1.0 is tagged in libby-docs repo
    hash = "";
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
    description = "Official documentation site for the LIBBY persona";
    homepage = "https://libby.agent.ruinous.ai";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
