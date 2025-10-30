{lib, ...}: {
  options.services.backup-docker-mariadb.enable = lib.options.mkEnableOption "backup-docker-mariadb";
  options.services.backup-docker-postgres.enable = lib.options.mkEnableOption "backup-docker-postgres";

  options.services.restic = {
    enableTerranas = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "enable restic using terranas backup";
    };

    terranasHostname = lib.mkOption {
      type = lib.types.str;
      default = "terranas.manage.farmhouse.meskill.network";
      description = "restic terranas hostname";
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
    enableJournal = lib.options.mkEnableOption "enableJournal";
    lokiUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://loki.meskill.farm";
      description = "Loki url fragment";
    };
  };
}
