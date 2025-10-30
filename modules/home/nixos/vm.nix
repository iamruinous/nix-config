{pkgs, ...}: {
  home.packages = with pkgs; [
    spice-gtk
    adwaita-icon-theme
  ];
}
