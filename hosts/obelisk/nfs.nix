{...}: {
  fileSystems = {
    "/nas/isos" = {
      device = "terranas.manage.farmhouse.meskill.network:/mnt/tank/share/isos";
      fsType = "nfs";
      options = ["nfsvers=4.2"];
    };
  };
}
