{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "pinentry-1password";
  version = "0.1.0";
  dontUnpack = true;

  propagatedBuildInputs = [
    pkgs.coreutils
  ];

  passthru.shellPath = "/bin/pinentry-1password";
  outputs = ["out"];

  buildPhase = ''
    mkdir -p $out/bin

    cat > $out/bin/pinentry-1password << 'EOF'
#!/usr/bin/env bash
# 1Password CLI Pinentry for GPG-Agent and other pinentry-compatible programs
# Based on https://gist.github.com/mrgrain/9c3519952d9af811bd7bf50bfcfaa16f

set -euo pipefail

# Check if OP_PIN_ITEM is set
if [[ -z "''${OP_PIN_ITEM:-}" ]]; then
  echo "ERR 83886179 No secret <General error>"
  exit 1
fi

# Check if op command is available
if ! command -v op &> /dev/null; then
  echo "ERR 83886179 1Password CLI not found <General error>"
  exit 1
fi

# Main pinentry protocol loop
while IFS= read -r cmd; do
  case "$cmd" in
    \#*)
      # Comments
      echo "OK"
      ;;
    GETPIN)
      # Retrieve the passphrase from 1Password
      if pin=$(op read "$OP_PIN_ITEM" 2>/dev/null); then
        echo "D $pin"
        echo "OK"
      else
        echo "ERR 83886179 Failed to read from 1Password <General error>"
      fi
      ;;
    BYE)
      echo "OK"
      exit 0
      ;;
    *)
      # All other commands return OK
      echo "OK"
      ;;
  esac
done
EOF

    chmod +x $out/bin/pinentry-1password
  '';

  installPhase = ''
    # No installation steps needed beyond what's done in buildPhase
    true
  '';

  meta = with pkgs.lib; {
    description = "1Password CLI pinentry program for GPG-Agent and rage";
    homepage = "https://github.com/iamruinous/nix-config";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "pinentry-1password";
    platforms = platforms.unix;
  };
}
