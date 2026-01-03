{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "xdg-remote";
  version = "1.0.0";
  dontUnpack = true;

  propagatedBuildInputs = with pkgs; [
    gum
    openssl
    python3
    curl
  ];

  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin

    # Substitute executable paths
    substitute ${./xdg-receiver.sh} $out/bin/xdg-remote-receiver \
      --replace '@gum@' '${pkgs.gum}' \
      --replace '@openssl@' '${pkgs.openssl}' \
      --replace '@python@' '${pkgs.python3}'
    
    substitute ${./xdg-shim.sh} $out/bin/xdg-remote-shim \
      --replace '@gum@' '${pkgs.gum}'

    substitute ${./xdg-open.sh} $out/bin/xdg-open \
      --replace '@curl@' '${pkgs.curl}' \
      --replace '@python@' '${pkgs.python3}'

    chmod +x $out/bin/xdg-remote-receiver
    chmod +x $out/bin/xdg-remote-shim
    chmod +x $out/bin/xdg-open
  '';

  installPhase = ''
    true
  '';

  meta = with pkgs.lib; {
    description = "Remote xdg-open shim for passing URLs from a remote environment to a local desktop";
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.unix;
  };
}
