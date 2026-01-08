{pkgs, ...}:
pkgs.buildGoModule rec {
  pname = "forgejo-mcp";
  version = "2.5.0";

  src = pkgs.fetchurl {
    url = "https://codeberg.org/goern/forgejo-mcp/archive/v${version}.tar.gz";
    hash = "sha256-oT2AYvMv0L6CBRNYi0ph6NaQQOMsROqQ8BPTDL8okcI=";
  };

  sourceRoot = "forgejo-mcp";

  # Delete the broken vendor directory and let Nix fetch dependencies
  postPatch = ''
    rm -rf vendor
  '';

  # Vendor hash computed from go.sum
  vendorHash = "sha256-tOTRbc735TrIZ7fL9EywKLLlePKWMMCeuhbQJGHUuk4=";

  # Build tags to exclude wiki package (Nix build compatibility)
  tags = ["nowiki"];

  # Set CGO_ENABLED=0 for static build
  env.CGO_ENABLED = 0;

  # Build flags to strip debug info
  ldflags = [
    "-s"
    "-w"
  ];

  meta = with pkgs.lib; {
    description = "MCP server for interacting with Forgejo/Gitea REST API";
    homepage = "https://codeberg.org/goern/forgejo-mcp";
    license = licenses.asl20;
    maintainers = [];
    mainProgram = "forgejo-mcp";
    platforms = platforms.unix;
  };
}
