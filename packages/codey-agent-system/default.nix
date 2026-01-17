{pkgs, ...}: let
  version = "0.12.1";
in
  pkgs.stdenv.mkDerivation {
    pname = "codey-agent-system";
    inherit version;

    src = pkgs.fetchzip {
      url = "https://forge.meskill.farm/iamruinous/codey-agent-system/releases/download/v${version}/codey-agent-system-${version}.zip";
      sha256 = "sha256-WYWYbnyPGilBmhJngjOD++KoKvZ6ScIek7EuT0Bj844=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/codey-agent-system
      cp -r AGENTS.md protocols skill $out/share/codey-agent-system/

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Codey Agent System - AGENTS.md, protocols, and skills for OpenCode";
      homepage = "https://forge.meskill.farm/iamruinous/codey-agent-system";
      license = licenses.mit;
      maintainers = [];
      platforms = platforms.all;
    };
  }
