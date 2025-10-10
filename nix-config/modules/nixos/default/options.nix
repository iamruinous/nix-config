{lib, ...}: {
  options.virtualisation.arion = {
    enable = lib.options.mkEnableOption "arion";
  };

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
}
