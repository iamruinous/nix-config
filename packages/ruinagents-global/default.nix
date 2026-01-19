{pkgs, ...}: let
  version = "0.8.2";
in
  pkgs.stdenv.mkDerivation {
    pname = "ruinagents-global";
    inherit version;

    src = pkgs.fetchzip {
      url = "https://forge.meskill.farm/iamruinous/ruinagents/releases/download/v${version}/ruinagents-${version}.zip";
      sha256 = "sha256-wIxY1cM+p4Y+iyIThbxOktY0TbV2M123fK0w8RU+W34=";
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
