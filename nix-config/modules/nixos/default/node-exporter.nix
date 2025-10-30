{...}: {
  services.prometheus = {
    exporters = {
      node = {
        enabledCollectors = ["systemd"];
        port = 9002;
      };
    };
  };
}
