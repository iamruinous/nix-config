{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    ghostscript
    xpdf
  ];
}
