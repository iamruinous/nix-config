# ruinous.tea.enable = true;
{
  config,
  lib,
  pkgs,
  flake,
  ...
}:
with lib; let
  cfg = config.ruinous.tea;
in {
  config = mkIf cfg.enable {
    home.packages = [
      pkgs.tea
    ];

    age.secrets.tea_config = {
      rekeyFile = flake + /files/configs/tea/config.yml.age;
      path = "${config.home.homeDirectory}/.config/tea/config.yml";
      mode = "600";
      symlink = true;
    };

    home.activation.manage-tea-config = lib.hm.dag.entryAfter ["writeBoundary"] ''
      CONFIG_DIR="${config.home.homeDirectory}/.config/tea"
      CONFIG_FILE="$CONFIG_DIR/config.yml"
      BACKUP_FILE="$CONFIG_FILE.nix-deployed"
      NIX_CONTENT_PATH="${config.age.secrets.tea_config.path}"

      $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"

      # If the config file has been modified at runtime, show a warning
      if [ -f "$CONFIG_FILE" ] && [ -f "$BACKUP_FILE" ] && ! diff -q "$BACKUP_FILE" "$CONFIG_FILE" > /dev/null 2>&1; then
          echo " "
          echo "------------------------------------------------------------------------"
          echo "⚠️  WARNING: Runtime changes detected in $CONFIG_FILE"
          echo "------------------------------------------------------------------------"
          echo "Nix is overwriting the file with its configured version."
          echo "To preserve your changes, add them to your Nix configuration."
          echo "Diff:"
          diff --color=always -u "$BACKUP_FILE" "$CONFIG_FILE" || true
          echo "------------------------------------------------------------------------"
          echo " "
      fi

      # Always write the Nix-defined content to the file and the backup.
      $DRY_RUN_CMD cp "$NIX_CONTENT_PATH" "$CONFIG_FILE"
      $DRY_RUN_CMD cp "$NIX_CONTENT_PATH" "$BACKUP_FILE"
      $DRY_RUN_CMD chmod 600 "$CONFIG_FILE" "$BACKUP_FILE"
    '';
  };
}
