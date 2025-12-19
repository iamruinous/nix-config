{perSystem, ...}: {
  # Accept agreements for unfree software
  nixpkgs.config = {
    allowUnfree = true;
    nvidia.acceptLicense = true;
  };

  nixpkgs.overlays = [
    (_final: _prev: {
      stable = perSystem.nixpkgs-stable;
    })
  ];

  # put allowed insecure packages here
  nixpkgs.config.permittedInsecurePackages = [
    "electron-36.9.5"
  ];
}
