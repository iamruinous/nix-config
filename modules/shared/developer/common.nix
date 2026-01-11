{
  flake,
  pkgs,
  ...
}: {
  # Import shared/universal for common nix settings
  imports = [flake.sharedModules.universal];

  nixpkgs.overlays = [
    flake.inputs.fenix.overlays.default
  ];

  # System packages - cross-platform developer utilities
  environment.systemPackages = with pkgs;
    [
      # dev tools
      devenv
      commitlint
      gitleaks
      prek
      jq
      just
      lazygit
      luarocks
      openssl
      ripgrep
      urlencode

      # languages
      bun
      go
      nodejs
      (python3.withPackages (ps:
        with ps; [
          pip
          virtualenv
        ]))
      uv

      # lsp and formatters
      alejandra
      basedpyright
      bash-language-server
      biome
      golangci-lint
      golangci-lint-langserver
      gopls
      harper
      lemminx
      lua-language-server
      marksman
      nil
      nixd
      ruff
      selene
      stylua
      taplo
      typos-lsp
      yaml-language-server

      # helpful cli utils
      vhs
      forgejo-cli
      gh
      tea

      # rust
      (fenix.stable.withComponents [
        "cargo"
        "clippy"
        "rust-src"
        "rustc"
        "rustfmt"
      ])
      rust-analyzer-nightly
    ]
    ++ (pkgs.lib.optionals pkgs.stdenv.isLinux [
      # zig currently broken on Darwin
      zig
      zls
    ]);
}
