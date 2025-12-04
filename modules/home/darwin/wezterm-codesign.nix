{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.wezterm;
  wezterm-codesigned = pkgs.wezterm-codesigned or pkgs.wezterm;
  signingIdentity = "Nix Signing";
in {
  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    # Copy and sign WezTerm during activation
    # Must copy because Nix store is read-only and codesign modifies files
    home.activation.signWezterm = lib.hm.dag.entryAfter ["writeBoundary"] ''
      SOURCE_APP="${wezterm-codesigned}/Applications/WezTerm.app"
      TARGET_APP="$HOME/Applications/WezTerm.app"

      # Check if signing identity exists
      if ! /usr/bin/security find-identity -v -p codesigning | grep -q "${signingIdentity}"; then
        echo "Note: No signing identity '${signingIdentity}' found. WezTerm notifications may not work."
        echo "Run 'nix run .#nix-codesign-cert' to create a signing certificate."
        exit 0
      fi

      # Check if already signed with our identity
      if [[ -d "$TARGET_APP" ]]; then
        if /usr/bin/codesign -dv "$TARGET_APP/wezterm-gui" 2>&1 | grep -q "Authority=${signingIdentity}"; then
          # Check if source is newer than target
          if [[ ! "$SOURCE_APP" -nt "$TARGET_APP" ]]; then
            echo "WezTerm already signed and up to date"
            exit 0
          fi
        fi
      fi

      echo "Copying WezTerm to ~/Applications for code signing..."
      mkdir -p "$HOME/Applications"
      rm -rf "$TARGET_APP"
      cp -RL "$SOURCE_APP" "$TARGET_APP"
      chmod -R u+w "$TARGET_APP"

      echo "Signing WezTerm with '${signingIdentity}'..."

      # WezTerm has a non-standard bundle layout with executables at root
      # codesign refuses to sign files inside a bundle with "unsealed contents"
      # Workaround: copy each executable out, sign it, copy it back
      TEMP_SIGN=$(mktemp -d)
      trap "rm -rf $TEMP_SIGN" EXIT

      for exe in wezterm wezterm-gui wezterm-mux-server strip-ansi-escapes; do
        if [[ -f "$TARGET_APP/$exe" ]]; then
          cp "$TARGET_APP/$exe" "$TEMP_SIGN/$exe"
          /usr/bin/codesign --force -s "${signingIdentity}" "$TEMP_SIGN/$exe"
          cp "$TEMP_SIGN/$exe" "$TARGET_APP/$exe"
        fi
      done

      echo "WezTerm signed successfully!"
    '';
  };
}
