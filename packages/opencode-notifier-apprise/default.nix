{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "opencode-notifier-apprise";
  version = "1.0.0";
  dontUnpack = true;

  propagatedBuildInputs = with pkgs; [
    curl
    jq
  ];

  passthru.shellPath = "/bin/apprise-notify";
  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/opencode-notifier-apprise

    # Install the shell script with path substitutions
    substitute ${./apprise-notify.sh} $out/bin/apprise-notify \
      --replace '@curl@' '${pkgs.curl}/bin/curl' \
      --replace '@jq@' '${pkgs.jq}/bin/jq'

    chmod +x $out/bin/apprise-notify

    # Copy TypeScript plugin source for manual installation
    cp ${./package.json} $out/share/opencode-notifier-apprise/package.json
    cp ${./tsconfig.json} $out/share/opencode-notifier-apprise/tsconfig.json
    cp -r ${./src} $out/share/opencode-notifier-apprise/src
  '';

  installPhase = ''
    # No additional installation steps needed
    true
  '';

  meta = with pkgs.lib; {
    description = "OpenCode plugin that sends notifications via Apprise API";
    longDescription = ''
      An OpenCode plugin that sends notifications through Apprise API when
      OpenCode needs user attention. Supports notifications for:
      - Session idle (waiting for user input)
      - Permission requests
      - Session errors

      Includes a standalone CLI tool (apprise-notify) for sending notifications
      directly from the command line.
    '';
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "apprise-notify";
    platforms = platforms.unix;
  };
}
