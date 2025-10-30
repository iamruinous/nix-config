{
  pkgs,
  perSystem,
  ...
}: {
  services.printing.drivers = [
    perSystem.self.nelko-pl70ebt
  ];

  hardware.printers = {
    ensurePrinters = [
      {
        name = "PL70e-BT";
        location = "Studio Desk";
        deviceUri = "usb:///PL70e-BT?serial=YY33230312";
        ppdOptions = {
          PageSize = "w288h432";
        };
        model = "Nelko/PL70e-BT.ppd";
      }
    ];
  };

  hardware.printers.ensureDefaultPrinter = "PL70e-BT";
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    cups
  ];
}
