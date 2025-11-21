# docker-mcp-gateway

Docker CLI plugin for MCP (Model Context Protocol) gateway.

## Overview

The Docker MCP Gateway is an official Docker CLI plugin that enables integration with the Model Context Protocol (MCP), allowing AI assistants and other tools to interact with Docker environments in a structured and controlled manner.

## Purpose

Provides a bridge between Docker and MCP-compatible tools, enabling:
- AI assistants to interact with Docker containers and images
- Controlled access to Docker operations through the MCP protocol
- Structured data exchange between Docker and AI tools

## Key Features

- Docker CLI plugin integration
- MCP protocol support for Docker operations
- Secure, controlled access to Docker functionality
- Works with Docker Desktop's MCP Toolkit feature

## Installation

This package is available to all hosts in this flake. To install it:

```nix
environment.systemPackages = with pkgs; [
  docker-mcp-gateway
];
```

### As a Docker CLI Plugin

The package automatically installs as a Docker CLI plugin. After installation, the plugin will be available at:
- `~/.docker/cli-plugins/docker-mcp` (manual installation)
- Via the Nix package which creates symlinks in the appropriate locations

## Usage

Once installed, the plugin can be invoked through the Docker CLI:

```sh
docker mcp --help
```

The plugin requires Docker Desktop with the MCP Toolkit feature enabled for full functionality.

## Requirements

- Docker (runtime dependency)
- Docker Desktop with MCP Toolkit (for production use)
- Go 1.24+ (build-time only, handled by Nix)

## Technical Details

- **Language**: Go
- **Version**: 0.28.0
- **Build**: Static binary with CGO disabled
- **Platform Support**: Linux (x86_64, ARM64), macOS (x86_64, ARM64)

## Build Details

The package is built using `buildGoModule` with:
- CGO disabled for static compilation
- Debug symbols stripped for smaller binary size
- Version information embedded at build time
- Installed as both a CLI plugin and standalone binary

## Upstream

- **Repository**: https://github.com/docker/mcp-gateway
- **License**: Apache 2.0
- **Documentation**: https://github.com/docker/mcp-gateway/tree/main/docs

## Notes

- This package builds the official Docker MCP Gateway from source
- The binary can be used standalone or as a Docker CLI plugin
- MCP protocol integration requires compatible tools or AI assistants
