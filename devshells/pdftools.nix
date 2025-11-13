{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    ghostscript
    paperjam
    poppler-utils
  ];
}
