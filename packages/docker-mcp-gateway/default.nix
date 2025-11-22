{pkgs, ...}:
pkgs.buildGoModule rec {
  pname = "docker-mcp-gateway";
  version = "0.28.0";

  src = pkgs.fetchFromGitHub {
    owner = "docker";
    repo = "mcp-gateway";
    rev = "v${version}";
    hash = "sha256-Cx8TTNyKrimY3qBsbEdPJ0Ug2eeNl6qtoSGEEfrTwok=";
  };

  # The vendor hash will need to be computed during the first build
  vendorHash = null;

  # Build from the cmd/docker-mcp directory
  subPackages = ["cmd/docker-mcp"];

  # Set CGO_ENABLED=0 as per the Makefile
  env.CGO_ENABLED = 0;

  # Build flags to strip debug info and embed version
  ldflags = [
    "-X github.com/docker/mcp-gateway/cmd/docker-mcp/version.Version=${version}"
    "-s"
    "-w"
  ];

  # Post-install: move binary to cli-plugins directory structure
  # This makes it work as a Docker CLI plugin
  postInstall = ''
    mkdir -p $out/docker/cli-plugins
    mv $out/bin/docker-mcp $out/docker/cli-plugins/docker-mcp

    # Create a wrapper in bin that points to the plugin location
    mkdir -p $out/bin
    ln -s $out/docker/cli-plugins/docker-mcp $out/bin/docker-mcp
  '';

  meta = with pkgs.lib; {
    description = "Docker CLI plugin for MCP (Model Context Protocol) gateway";
    homepage = "https://github.com/docker/mcp-gateway";
    license = licenses.asl20;
    maintainers = [];
    mainProgram = "docker-mcp";
    platforms = platforms.unix ++ platforms.darwin;
  };
}
