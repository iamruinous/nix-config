{ pkgs, ... }:

pkgs.mkShell {
  packages = with pkgs; [
    python313
    (python313.withPackages (p: [
      p.pip
      p.virtualenv
    ]))
  ];

  shellHook = ''
    echo "Entering Python 3.13 devshell"
  '';
}