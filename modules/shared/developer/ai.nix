{
  flake,
  pkgs,
  lib,
  ...
}: let
  llmAgentsPkgs = flake.inputs.llm-agents.packages.${pkgs.system};
in {
  # AI CLI tools for developers
  # - Linux: Install from llm-agents flake
  # - macOS: Install via Homebrew (see modules/darwin/desktop/brew.nix)
  environment.systemPackages =
    # Sandboxing tools (Linux only)
    lib.optionals pkgs.stdenv.isLinux [
      pkgs.socat
      pkgs.bubblewrap
    ]
    # AI CLI packages (Linux only - macOS uses Homebrew)
    ++ lib.optionals pkgs.stdenv.isLinux [
      llmAgentsPkgs.codex
      llmAgentsPkgs.claude-code
      llmAgentsPkgs.gemini-cli
    ];
}
