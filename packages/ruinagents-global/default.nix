{pkgs, ...}: let
  version = "0.6.2";
in
  pkgs.stdenv.mkDerivation {
    pname = "ruinagents-global";
    inherit version;

    src = pkgs.fetchzip {
      url = "https://forge.meskill.farm/iamruinous/ruinagents/releases/download/v${version}/ruinagents-${version}.zip";
      sha256 = "sha256-Tkah3liTeOSsd4M+JkUjPIa30ygepMcev3VZTRnNAfE=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      installDir="$out/share/ruinagents-global"
      mkdir -p "$installDir"

      cp -r AGENTS.md $installDir/

      if [ -d "context" ]; then
        cp -r "context" "$installDir/"
      fi

      if [ -d "skill" ]; then
        cp -r "skill" "$installDir/"
      fi

      if [ -d "command" ]; then
        cp -r "command" "$installDir/"
      fi

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Ruinagents Global - AGENTS.md, docs, and skills for OpenCode";
      homepage = "https://forge.meskill.farm/iamruinous/ruinagents";
      license = licenses.mit;
      maintainers = [];
      platforms = platforms.all;
    };
  }
