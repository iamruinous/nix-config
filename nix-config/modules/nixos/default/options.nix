{lib, ...}: {
  options.services.backup-docker-mariadb.enable = lib.options.mkEnableOption "backup-docker-mariadb";
  options.services.backup-docker-postgres.enable = lib.options.mkEnableOption "backup-docker-postgres";

  options.services.restic = {
    terranas = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "restic";
    };
  };

  options.services.printing = {
    discoverable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "make printers discoverable";
    };
  };

  options.services.alloy = {
    loki_url = lib.mkOption {
      type = lib.types.str;
      default = "https://loki.meskill.farm";
      description = "Loki url fragment";
    };
  };
  options.services.alloy.enableJournal = lib.options.mkEnableOption "enableJournal";
}
