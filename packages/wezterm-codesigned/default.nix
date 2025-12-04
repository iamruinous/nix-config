{
  pkgs,
  signingIdentity ? "Nix Signing",
  ...
}: let
  # Script to sign wezterm - runs as user with keychain access
  signScript = pkgs.writeShellScript "sign-wezterm" ''
    set -euo pipefail
    WEZTERM_APP="$1"
    IDENTITY="${signingIdentity}"

    if [[ ! -d "$WEZTERM_APP" ]]; then
      echo "Error: WezTerm.app not found at $WEZTERM_APP"
      exit 1
    fi

    # Check if already signed with our identity
    if /usr/bin/codesign -dv "$WEZTERM_APP/wezterm-gui" 2>&1 | grep -q "Authority=$IDENTITY"; then
      echo "WezTerm is already signed with '$IDENTITY'"
      exit 0
    fi

    echo "Signing WezTerm.app with '$IDENTITY'..."

    if ! /usr/bin/security find-identity -v -p codesigning | grep -q "$IDENTITY"; then
      echo "Error: No valid signing identity '$IDENTITY' found!"
      echo "Run 'nix run .#nix-codesign-cert' to create one."
      exit 1
    fi

    # WezTerm has executables in the bundle root (non-standard layout)
    # Sign each executable individually first
    for exe in "$WEZTERM_APP/wezterm" "$WEZTERM_APP/wezterm-gui" \
               "$WEZTERM_APP/wezterm-mux-server" "$WEZTERM_APP/strip-ansi-escapes"; do
      if [[ -f "$exe" ]]; then
        /usr/bin/codesign --force -s "$IDENTITY" "$exe"
      fi
    done

    # Sign the Contents directory (standard app structure)
    if [[ -d "$WEZTERM_APP/Contents" ]]; then
      /usr/bin/codesign --deep --force -s "$IDENTITY" "$WEZTERM_APP/Contents"
    fi

    # Verify at least the main GUI binary
    /usr/bin/codesign --verify "$WEZTERM_APP/wezterm-gui"
    echo "Code signing complete!"
  '';
in
  # This package wraps WezTerm for macOS with code signing support.
  # The signing happens via home-manager activation, not during build,
  # because builds run as a separate user without keychain access.
  #
  # Prerequisites (one-time setup):
  #   nix run .#nix-codesign-cert
  pkgs.stdenv.mkDerivation {
    pname = "wezterm-codesigned";
    inherit (pkgs.wezterm) version;

    dontUnpack = true;

    buildPhase = ''
      runHook preBuild

      # Copy the entire wezterm package
      cp -r ${pkgs.wezterm} $out
      chmod -R u+w $out

      # Include signing script for activation
      mkdir -p $out/libexec
      cp ${signScript} $out/libexec/sign-wezterm

      runHook postBuild
    '';

    dontInstall = true;

    # Expose the app path and sign script for activation
    passthru = {
      appPath = "/Applications/WezTerm.app";
      inherit signScript;
    };

    meta = with pkgs.lib; {
      inherit (pkgs.wezterm.meta) description homepage license mainProgram;
      platforms = platforms.darwin;
      maintainers = [];
    };
  }
