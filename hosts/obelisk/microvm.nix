{
  flake,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    flake.inputs.microvm.nixosModules.host
    flake.inputs.impermanence.nixosModules.impermanence
  ];

  microvm.autostart = ["messy-tty" "ruinous-tty" "builder-tty"];
  microvm.vms = {
    messy-tty = {
      inherit flake;
      updateFlake = "github:iamruinous/nix-config/main";
    };
    ruinous-tty = {
      inherit flake;
      updateFlake = "github:iamruinous/nix-config/main";
    };
    builder-tty = {
      inherit flake;
      updateFlake = "github:iamruinous/nix-config/main";
    };
  };

  # make sure directories exist or vm boot will fail
  systemd.tmpfiles.rules = [
    "d /persistent/microvms/messy-tty/persistent 0770 root root -"
    "d /persistent/microvms/ruinous-tty/persistent 0770 root root -"
    "d /persistent/microvms/builder-tty/persistent 0770 root root -"
  ];
}
