{
  pkgs,
  lib,
  ...
}: let
  pname = "messy-discord-bot";
  version = "1.0.0";

  # Build the Node.js application
  # To update npmDepsHash after changing package.json:
  # 1. cd packages/messy-discord-bot && npm install
  # 2. nix build .#messy-discord-bot --rebuild 2>&1 | grep "got:"
  # 3. Update the hash below with the "got:" value
  app = pkgs.buildNpmPackage {
    inherit pname version;

    src = lib.cleanSource ./.;

    # Hash of npm dependencies - update after running npm install
    # Use: nix hash to-sri sha256 $(nix-prefetch-npm-deps package-lock.json)
    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

    # Don't run npm build, just install dependencies
    dontNpmBuild = true;

    # Install the application
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/${pname}
      cp -r node_modules $out/lib/${pname}/
      cp -r src $out/lib/${pname}/
      cp package.json $out/lib/${pname}/

      mkdir -p $out/bin
      cat > $out/bin/${pname} << EOF
      #!/usr/bin/env bash
      exec ${pkgs.nodejs}/bin/node $out/lib/${pname}/src/index.js "\$@"
      EOF
      chmod +x $out/bin/${pname}
      runHook postInstall
    '';

    meta = {
      description = "Discord bot that forwards messages to n8n webhook for Messy assistant";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = pname;
    };
  };

  # Build the Docker image
  dockerImage = pkgs.dockerTools.buildLayeredImage {
    name = "ghcr.io/iamruinous/${pname}";
    tag = version;

    contents = [
      pkgs.nodejs
      pkgs.cacert # Required for HTTPS connections
    ];

    extraCommands = ''
      mkdir -p app
      cp -r ${app}/lib/${pname}/* app/
    '';

    config = {
      Cmd = ["${pkgs.nodejs}/bin/node" "/app/src/index.js"];
      WorkingDir = "/app";
      Env = [
        "NODE_ENV=production"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
    };
  };
in
  # Export both the app and Docker image
  app
  // {
    inherit dockerImage;
  }
