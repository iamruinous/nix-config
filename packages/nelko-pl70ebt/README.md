# nelko-pl70ebt

CUPS printer driver for the Nelko PL70e-BT label printer.

## Description

This package provides the CUPS driver for the Nelko PL70e-BT Bluetooth label printer. It extracts and packages the official Linux driver from the vendor's .deb distribution for use in NixOS.

## Version

3.0.1.407

## Included Components

The package installs:
- PPD (PostScript Printer Description) files for the PL70e-BT and PL420 models
- `rastertolabel` CUPS filter for converting raster images to the printer's format

## Installation Paths

- PPD files: `$out/share/cups/model/Nelko/`
- CUPS filters: `$out/lib/cups/filter/Nelko/`

## Usage

Add this package to your NixOS configuration to enable support for the Nelko PL70e-BT printer:

```nix
services.printing = {
  enable = true;
  drivers = [ pkgs.nelko-pl70ebt ];
};
```

After adding the driver, you can configure the printer through the CUPS web interface or using standard CUPS tools.

## Source

The driver is fetched from the official Nelko CDN: https://cdn.shopify.com/s/files/1/0657/6626/0980/files/NELKO_PL70e-BT_Linux_v3.0.1.407.deb

## Dependencies

- CUPS (Common Unix Printing System)

## Links

- Homepage: https://nelkoprint.com/
