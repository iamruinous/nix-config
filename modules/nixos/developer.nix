{
  flake,
  pkgs,
  ...
}: {
  imports = [flake.nixosModules.common];

  nixpkgs.overlays = [flake.inputs.fenix.overlays.default];

  # System packages
  environment.systemPackages = with pkgs;
    [
      # dev tools
      # aider-chat
      devenv
      git-secrets
      jq
      just
      lazygit
      luarocks
      #playwright
      #playwright-driver.browsers
      ripgrep

      # languages
      go
      nodejs
      (python3.withPackages (ps:
        with ps; [
          pip
          virtualenv
          # llm
          # llm-anthropic
          # llm-gemini
        ]))
      uv
      # zig # TODO: broken

      # lsp and formatters
      alejandra
      basedpyright
      biome
      golangci-lint
      golangci-lint-langserver
      gopls
      harper
      lemminx
      lua-language-server
      marksman
      nil
      ruff
      selene
      stylua
      taplo
      typos-lsp
      yaml-language-server
      # zls # TODO: zig broken

      forgejo-cli

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
      # ai tools (brew on macos)
      claude-code
      codex
      crush
      gemini-cli
      opencode

      # sandboxing
      socat
      bubblewrap

      zig # zig currently broken on Darwin
      zls
    ]);
}
