{lib, ...}: {
  # Install bottom via home-manager module
  programs.bottom = {
    enable = lib.mkDefault true;
    settings = {
      flags = {
        avg_cpu = true;
        temperature_type = "c";
      };

      colors = {
        low_battery_color = "red";
      };
    };
  };
}
