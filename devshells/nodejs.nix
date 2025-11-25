{ pkgs, ... }:

pkgs.mkShell {
  packages = with pkgs; [
    nodejs
  ];

  shellHook = ''
    echo "Node.js development environment"
    echo "Node: $(node --version)"
    echo "npm: $(npm --version)"
    echo "npx: $(npx --version)"
  '';
}
