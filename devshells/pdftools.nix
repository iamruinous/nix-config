{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    ghostscript
    xpdf
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "xpdf-4.05"
  ];
}
