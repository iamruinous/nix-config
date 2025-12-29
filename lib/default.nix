# Ruinous Library - Custom helper functions for this NixOS configuration
#
# Usage in flake.nix:
#   ruinousLib = import ./lib { inherit inputs; };
#   piHosts = ruinousLib.pi.discoverPiHosts { ... };
{inputs}: {
  # Pi-specific helper functions for Raspberry Pi host discovery and configuration
  pi = import ./pi.nix {inherit inputs;};
}
