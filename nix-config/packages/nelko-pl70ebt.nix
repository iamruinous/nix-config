{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "nelko-pl70ebt";
  version = "3.0.1.407";

  src = pkgs.fetchurl {
    url = "https://cdn.shopify.com/s/files/1/0657/6626/0980/files/NELKO_PL70e-BT_Linux_v3.0.1.407.deb";
    sha256 = "sha256-IinWigCaA9WVWTeTL6x+AXQyvBGCUbOKu1shjYjabUY=";
  };

  buildInputs = [pkgs.cups];
  nativeBuildInputs = [pkgs.dpkg];

  installPhase = ''
    # Create the necessary directories in the output
    install -d $out/share/cups/model/Nelko
    install -d $out/lib/cups/filter/Nelko/Filter
    install -d $out/lib/cups/filter/Nelko/PPDs

    # Copy the PPD file and the filter executable
    # The exact paths might differ, you may need to inspect the extracted contents
    install -m 644 usr/share/cups/model/Nelko/PL420.ppd $out/share/cups/model/Nelko/
    install -m 644 usr/share/cups/model/Nelko/PL70e-BT.ppd $out/share/cups/model/Nelko/
    install -m 644 usr/lib/cups/filter/Nelko/PPDs/PL420.ppd $out/lib/cups/filter/Nelko/PPDs/
    install -m 644 usr/lib/cups/filter/Nelko/PPDs/PL70e-BT.ppd $out/lib/cups/filter/Nelko/PPDs/
    install -m 755 usr/lib/cups/filter/Nelko/Filter/rastertolabel $out/lib/cups/filter/Nelko/Filter/
  '';

  meta = {
    description = "Nelko PL70e-BT printer driver";
    homepage = "https://nelkoprint.com/";
    license = pkgs.lib.licenses.mit; # TODO: figure out how to deal with unfree
    platforms = ["x86_64-linux"];
    maintainers = [pkgs.lib.maintainers.jmeskill];
  };

  passthru.tests = {
    check-filter = pkgs.runCommand "check-nelko-pl70ebt-filter" {} ''
      filter_path="${pkgs.nelko-pl70ebt}/lib/cups/filter/Nelko/Filter/rastertolabel"
      if [ ! -f "$filter_path" ]; then
        echo "Filter executable not found at $filter_path"
        exit 1
      fi
      if [ ! -x "$filter_path" ]; then
        echo "Filter is not executable at $filter_path"
        exit 1
      fi
      echo "Test passed"
      touch $out
    '';
  };
}
