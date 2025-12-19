{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    # Core PDF tools
    ghostscript
    poppler-utils

    # PDF manipulation
    pdftk
    qpdf
    paperjam

    # OCR and search
    ocrmypdf
    pdfgrep

    # Image to PDF
    img2pdf

    # Python with PDF packages
    (python313.withPackages (p: [
      p.pip
      p.virtualenv
      # PDF manipulation
      p.pikepdf
      p.pdfminer-six
      p.pdf2docx
      p.pdftotext
      # Document conversion
      p.gotenberg-client
      p.python-docx
      p.python-pptx
      p.md2pdf
      # reMarkable
      p.rmrl
    ]))
  ];

  shellHook = ''
    echo "PDF Tools development environment"
    echo "pdftk, qpdf, ocrmypdf, pdfgrep, img2pdf, poppler-utils"
  '';
}
