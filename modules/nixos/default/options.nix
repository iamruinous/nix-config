{lib, ...}: {
  options = {
    ruinous.mariadb.docker.backup.enable = lib.options.mkEnableOption "backup-docker-mariadb";
    ruinous.postgres.docker.backup.enable = lib.options.mkEnableOption "backup-docker-postgres";

    ruinous.restic.terranas = {
      enable = lib.mkEnableOption "enable terranas restic backup";

      username = lib.mkOption {
        type = lib.types.str;
        default = "tmbackup";
        description = "restic terranas username";
      };

      hostname = lib.mkOption {
        type = lib.types.str;
        default = "terranas.manage.farmhouse.meskill.network";
        description = "restic terranas hostname";
      };
    };

    ruinous.printing.discoverable = lib.mkEnableOption "make printers discoverable";

    ruinous.alloy = {
      journal.enable = lib.options.mkEnableOption "enable alloy journal";

      loki.url = lib.mkOption {
        type = lib.types.str;
        default = "https://loki.meskill.farm";
        description = "Loki url fragment";
      };
    };
  };
}
