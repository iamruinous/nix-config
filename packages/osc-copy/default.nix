{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "osc-copy";
  version = "1.0.0";
  dontUnpack = true;

  buildPhase = ''
    mkdir -p $out/bin
    substitute ${./osc-copy.sh} $out/bin/osc-copy \
      --replace-fail "base64" "${pkgs.coreutils}/bin/base64" \
      --replace-fail "tr " "${pkgs.coreutils}/bin/tr "
    chmod +x $out/bin/osc-copy
  '';

  installPhase = "true";

  meta = with pkgs.lib; {
    description = "Copy to clipboard via OSC 52 escape sequence";
    longDescription = ''
      Copies stdin or file contents to the system clipboard using the OSC 52
      escape sequence. Works over SSH and inside tmux sessions.

      Requires a terminal that supports OSC 52 (wezterm, kitty, iTerm2, etc).
    '';
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "osc-copy";
  };
}
