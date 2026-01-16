{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "codey-docs";
  version = "0.1.1";

  src = pkgs.fetchgit {
    url = "https://forge.meskill.farm/iamruinous/codey-docs.git";
    rev = "v${version}";
    hash = "sha256-P8J0xKJd6/VkUrEqydpZ8GOri2nPUkxbd9o8qsOt5yU=";
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
    homepage = "https://codey.bot.ruinous.ai";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
