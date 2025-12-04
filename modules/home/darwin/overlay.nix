{perSystem, ...}: {
  nixpkgs.overlays = [
    (_final: prev: {
      # Replace wezterm with codesigned version for macOS notifications
      wezterm = perSystem.self.wezterm-codesigned;
    })
  ];
}
