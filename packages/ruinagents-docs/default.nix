{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "ruinagents-docs";
  version = "0.7.0";

  src = pkgs.fetchzip {
    url = "https://forge.meskill.farm/iamruinous/ruinagents/releases/download/v${version}/ruinagents-docs-${version}.zip";
    sha256 = "sha256-WIVEuEf06gbdiR3qDlaACpTILbKXyvNqz6lfRWrOdwM=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Copy built site to output
    mkdir -p $out
    cp -r * $out/

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
