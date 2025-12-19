{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    # Runtime & package managers
    nodejs
    pnpm
    yarn

    # TypeScript
    nodePackages.typescript
    nodePackages.ts-node

    # Language servers (for IDE support)
    nodePackages.typescript-language-server

    # Linting & formatting
    nodePackages.prettier
    nodePackages.eslint

    # Native module compilation (for packages with native bindings)
    python3
    gnumake
    gcc
  ];

  shellHook = ''
    echo "Node.js development environment"
    echo "Node: $(node --version)"
    echo "pnpm: $(pnpm --version)"
    echo "TypeScript: $(tsc --version)"
  '';
}
