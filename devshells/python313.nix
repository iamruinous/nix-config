{pkgs, ...}:
pkgs.mkShell {
  packages = with pkgs; [
    # Python with common packages
    (python313.withPackages (p: [
      p.pip
      p.virtualenv
      p.setuptools
      p.wheel
      p.build
    ]))

    # Modern package management
    uv

    # Linting & formatting
    ruff

    # Type checking
    pyright

    # Language server (for IDE support)
    python313Packages.python-lsp-server
  ];

  shellHook = ''
    echo "Python 3.13 development environment"
    echo "Python: $(python --version)"
    echo "uv: $(uv --version)"
    echo "ruff: $(ruff --version)"
  '';
}