{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf config.ruinous.kernel.useLatest {
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };
}
