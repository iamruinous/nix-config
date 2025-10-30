{lib, ...}: {
  options.services.todoist-auto = {
    enable = lib.mkOption {
      default = false;
      description = ''
        Whether to enable todoist auto-sync.
      '';
    };
  };

  options.services.vdirsyncer-auto = {
    enable = lib.mkOption {
      default = false;
      description = ''
        Whether to enable vdirsyncer auto-sync.
      '';
    };
  };
}
