{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    # Bun runtime (includes bundler, transpiler, package manager)
    bun

    # TypeScript (for type checking - bun runs TS natively)
    nodePackages.typescript

    # Language servers (for IDE support)
    nodePackages.typescript-language-server

    # Linting & formatting
    nodePackages.prettier
    nodePackages.eslint
  ];

  shellHook = ''
    echo "Bun development environment"
    echo "Bun: $(bun --version)"
    echo "TypeScript: $(tsc --version)"
  '';
}
