{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    ghostscript
    paperjam
    poppler-utils
    python313
    (python313.withPackages (p: [
      p.pip
      p.virtualenv
      p.gotenberg-client
      p.python-docx
      p.python-pptx
      p.md2pdf
      p.pdftotext
      p.rmrl
    ]))
  ];
}
