{ pkgs, ... }:

pkgs.mkShell {
  packages = with pkgs; [
    # Node.js runtime (n8n uses Node 18+)
    nodejs_22

    # Package managers
    nodePackages.npm
    nodePackages.pnpm

    # TypeScript tooling
    nodePackages.typescript
    nodePackages.typescript-language-server

    # Linting and formatting
    nodePackages.eslint
    nodePackages.prettier

    # Build tools
    turbo

    # Git
    git
  ];

  shellHook = ''
    echo "n8n Custom Node Development Environment"
    echo "========================================"
    echo "Node: $(node --version)"
    echo "npm: $(npm --version)"
    echo "pnpm: $(pnpm --version)"
    echo "TypeScript: $(tsc --version)"
    echo ""
    echo "Installing @n8n/node-cli globally..."
    npm install -g @n8n/node-cli 2>/dev/null || true
    echo ""
    echo "Commands:"
    echo "  n8n-node new <name>  - Create a new node project"
    echo "  n8n-node dev         - Run n8n with your node (hot reload)"
    echo "  n8n-node build       - Build your node"
    echo ""
  '';

  env = {
    # Ensure npm/pnpm use local node_modules
    NODE_PATH = "./node_modules";
  };
}
