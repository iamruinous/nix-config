{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "nate-docs";
  version = "0.1.0";

  src = pkgs.fetchgit {
    url = "https://forge.meskill.farm/iamruinous/nate-docs.git";
    rev = "v${version}";
    hash = "sha256-XqbirncGm5ONzqHIPjyFMQmkYFjNUPeaoU1rS6w/ZMM=";
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
    description = "Official documentation site for the NATE persona";
    homepage = "https://nate.bot.ruinous.ai";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
