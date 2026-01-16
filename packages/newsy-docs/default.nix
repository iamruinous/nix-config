{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "newsy-docs";
  version = "0.1.0";

  # NOTE: Repository must be public for fetchgit to work
  src = pkgs.fetchgit {
    url = "https://forge.meskill.farm/iamruinous/newsy-docs.git";
    rev = "v${version}";
    hash = "sha256-efiEP0iu+t79SOP+ifWv8Xpq7TC2EIQ6r9dgJw/Lupc=";
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
    description = "Documentation site for NEWSY - The Meskill Family News Desk";
    homepage = "https://newsy.bot.ruinous.ai";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
