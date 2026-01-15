{pkgs, ...}: let
  version = "0.11.0";
in
  pkgs.stdenv.mkDerivation {
    pname = "codey-agent-system";
    inherit version;

    src = pkgs.fetchzip {
      url = "https://forge.meskill.farm/iamruinous/codey-agent-system/releases/download/v${version}/codey-agent-system-${version}.zip";
      sha256 = "sha256-Rf+Hlf8+qJ8DZmcP1g7JTJp7niX9S8Ht9fUyH4nk0Uc=";
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
