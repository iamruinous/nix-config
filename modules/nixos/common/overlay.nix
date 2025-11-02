{perSystem, ...}: {
  nixpkgs.overlays = [
    (_final: _prev: {
      inherit (perSystem) self;
      nelko-pl70ebt = perSystem.self.nelko-pl70ebt;
    })
  ];
}
