{pkgs, ...}: let
  version = "0.8.3";
in
  pkgs.stdenv.mkDerivation {
    pname = "ruinagents-global";
    inherit version;

    src = pkgs.fetchzip {
      url = "https://forge.meskill.farm/iamruinous/ruinagents/releases/download/v${version}/ruinagents-${version}.zip";
      sha256 = "sha256-1pv3oaKtxtltEslpO13p92rKuD+sqcYXjFufuyPN8eU=";
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
