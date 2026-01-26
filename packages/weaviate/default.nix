{pkgs, ...}:
pkgs.stdenv.mkDerivation rec {
  pname = "weaviate";
  version = "1.35.3";

  src = pkgs.fetchurl {
    url = "https://github.com/weaviate/weaviate/releases/download/v${version}/weaviate-v${version}-linux-amd64.tar.gz";
    sha256 = "33492e7dd8813745954bfd8cc0d525bf72285fcf5c5175b3ef3a67d38e5d4ea9";
  };

  # The tarball extracts directly (no subdirectory)
  sourceRoot = ".";

  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
  ];

  # Weaviate binary may need these runtime libs
  buildInputs = with pkgs; [
    stdenv.cc.cc.lib # libstdc++
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 weaviate $out/bin/weaviate

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Weaviate is an open-source vector database";
    longDescription = ''
      Weaviate is an open-source vector database that stores both objects and
      vectors, allowing for the combination of vector search with structured
      filtering with the fault tolerance and scalability of a cloud-native
      database.
    '';
    homepage = "https://weaviate.io/";
    changelog = "https://github.com/weaviate/weaviate/releases/tag/v${version}";
    license = licenses.bsd3;
    maintainers = [];
    mainProgram = "weaviate";
    platforms = ["x86_64-linux"];
  };
}
