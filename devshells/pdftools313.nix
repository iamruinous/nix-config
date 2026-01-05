{pkgs, ...}:
let
  # Override weasyprint to skip failing tests (pixel-level 2D transform rendering issues)
  python = pkgs.python313.override {
    packageOverrides = final: prev: {
      weasyprint = prev.weasyprint.overridePythonAttrs {
        doCheck = false;
      };
    };
  };
in
pkgs.mkShell {
  packages = with pkgs; [
    # Python with PDF packages (first to ensure correct Python version in PATH)
    (python.withPackages (p: [
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
  ];

  shellHook = ''
    echo "PDF Tools development environment (Python 3.13)"
    echo "pdftk, qpdf, ocrmypdf, pdfgrep, img2pdf, poppler-utils"
  '';
}
