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

      # Generate ETag sidecar files for Caddy cache busting
      # Nix store files have fixed mtime (epoch 1), so Caddy's default ETags
      # don't change between deployments. These .etag files contain content
      # hashes that Caddy reads via etag_file_extensions directive.
      # ETags must be quoted per RFC 7232.
      echo "Generating ETag sidecar files..."
      find $out -type f ! -name '*.etag' | while read -r file; do
        hash=$(${pkgs.coreutils}/bin/sha256sum "$file" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
        echo "\"$hash\"" > "$file.etag"
      done
      echo "ETag generation complete"
    '';

    meta = with pkgs.lib; {
      description = "Documentation for nix-config with ETag support for cache busting";
      homepage = "https://github.com/iamruinous/nix-config";
      license = licenses.mit;
      platforms = platforms.all;
    };
  }
