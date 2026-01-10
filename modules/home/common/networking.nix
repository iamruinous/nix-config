{
  osConfig,
  lib,
  ...
}: {
  options.networking = lib.mkOption {
    type = lib.types.anything;
    default =
      if osConfig != null && osConfig ? networking
      then {
        inherit
          (osConfig.networking)
          domain
          hostName
          ;
      }
      else {
        domain = "";
        hostName = "unknown";
      };
  };
}
