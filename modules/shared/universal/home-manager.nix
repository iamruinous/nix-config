{...}: {
  # Backup existing files before home-manager replaces them
  # This prevents activation failures when files already exist
  home-manager.backupFileExtension = "hmbackup";
}
