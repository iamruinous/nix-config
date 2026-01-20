{pkgs, ...}: let
  # Python with MkDocs Material theme for documentation
  mkdocsEnv = pkgs.python313.withPackages (ps:
    with ps; [
      mkdocs
      mkdocs-material
      mkdocs-material-extensions
      pymdown-extensions
    ]);
in
  pkgs.stdenv.mkDerivation {
    pname = "nix-config-docs";
    version = "0.1.0";
    src = ../../.;

    nativeBuildInputs = [mkdocsEnv];

    buildPhase = ''
      mkdocs build
    '';

    installPhase = ''
      cp -r site $out
    '';

    meta = with pkgs.lib; {
      description = "Documentation for nix-config";
      homepage = "https://github.com/iamruinous/nix-config";
      license = licenses.mit;
      platforms = platforms.all;
    };
  }
