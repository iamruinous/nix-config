{...}: {
  services.printing.cups-pdf = {
    enable = true;
    instances = {
      Paperless.settings = {
        Out = "/nas/paperless/consume";
        AnonDirName = "/nas/paperless/consume";
      };
    };
  };

  hardware.printers.ensureDefaultPrinter = "Paperless";
}
