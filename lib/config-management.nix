# Runtime-Writable Config Management Library
#
# Provides helper functions for creating activation scripts that manage
# configuration files which need to be runtime-writable while maintaining
# Nix-declared defaults.
#
# Pattern:
# 1. Copy Nix-defined content to writable location at activation
# 2. Track last-deployed version in .nix-deployed backup
# 3. Detect runtime changes and warn with colored diff
# 4. Always overwrite with Nix content (declarative management)
#
# Usage:
#   let
#     configMgmt = import ./lib/config-management.nix { inherit lib pkgs config; };
#   in {
#     home.activation.my-config = configMgmt.manageJsonFile {
#       name = "my-app-settings";
#       configDir = "\${config.home.homeDirectory}/.config/my-app";
#       configFile = "settings.json";
#       content = { model = "gpt-4"; plugins = []; };
#     };
#   }
{
  lib,
  pkgs,
  config,
}:
with lib; {
  # Generate activation script for a JSON config file
  #
  # Args:
  #   name: Unique identifier for this activation script
  #   configDir: Directory path (e.g., "$HOME/.config/app")
  #   configFile: Filename (e.g., "settings.json")
  #   content: Nix attrset to convert to JSON
  #
  # Returns: home.activation DAG entry
  manageJsonFile = {
    name,
    configDir,
    configFile,
    content,
  }: let
    nixContent = builtins.toJSON content;
  in
    mkActivationScript {
      inherit name configDir configFile;
      nixContent = nixContent;
    };

  # Generate activation script for a YAML config file
  #
  # Args:
  #   name: Unique identifier for this activation script
  #   configDir: Directory path
  #   configFile: Filename
  #   content: Nix attrset to convert to YAML
  #
  # Returns: home.activation DAG entry
  manageYamlFile = {
    name,
    configDir,
    configFile,
    content,
  }: let
    yamlFormat = pkgs.formats.yaml {};
    nixContent = builtins.readFile (yamlFormat.generate "temp" content);
  in
    mkActivationScript {
      inherit name configDir configFile;
      nixContent = nixContent;
    };

  # Generate activation script for a plain text config file
  #
  # Args:
  #   name: Unique identifier for this activation script
  #   configDir: Directory path
  #   configFile: Filename
  #   content: String content
  #
  # Returns: home.activation DAG entry
  manageTextFile = {
    name,
    configDir,
    configFile,
    content,
  }:
    mkActivationScript {
      inherit name configDir configFile;
      nixContent = content;
    };

  # Generate activation script for a config file from a template file
  #
  # Args:
  #   name: Unique identifier for this activation script
  #   configDir: Directory path
  #   configFile: Filename
  #   templateFile: Path to template file in Nix store
  #
  # Returns: home.activation DAG entry
  manageFromTemplate = {
    name,
    configDir,
    configFile,
    templateFile,
  }:
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      CONFIG_DIR="${configDir}"
      CONFIG_FILE="$CONFIG_DIR/${configFile}"
      BACKUP_FILE="$CONFIG_FILE.nix-deployed"
      TEMPLATE_FILE="${templateFile}"

      $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"

      # Warn about runtime changes
      if [ -f "$CONFIG_FILE" ] && [ -f "$BACKUP_FILE" ] && ! diff -q "$BACKUP_FILE" "$TEMPLATE_FILE" > /dev/null 2>&1; then
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

      # Always write Nix content
      $DRY_RUN_CMD cp "$TEMPLATE_FILE" "$CONFIG_FILE"
      $DRY_RUN_CMD cp "$TEMPLATE_FILE" "$BACKUP_FILE"
    '';

  # Internal: Core activation script generator
  #
  # Args:
  #   name: Unique identifier
  #   configDir: Directory path
  #   configFile: Filename
  #   nixContent: String content to write
  #
  # Returns: home.activation DAG entry
  mkActivationScript = {
    name,
    configDir,
    configFile,
    nixContent,
  }:
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      CONFIG_DIR="${configDir}"
      CONFIG_FILE="$CONFIG_DIR/${configFile}"
      BACKUP_FILE="$CONFIG_FILE.nix-deployed"
      NIX_CONTENT='${nixContent}'

      $DRY_RUN_CMD mkdir -p "$CONFIG_DIR"

      # Warn about runtime changes
      if [ -f "$CONFIG_FILE" ] && [ -f "$BACKUP_FILE" ] && ! diff -q "$BACKUP_FILE" <(echo "$NIX_CONTENT") > /dev/null 2>&1; then
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

      # Always write Nix content
      echo "$NIX_CONTENT" > "$CONFIG_FILE"
      echo "$NIX_CONTENT" > "$BACKUP_FILE"
    '';
}
