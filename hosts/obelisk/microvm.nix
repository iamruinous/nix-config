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
      updateFlake = "git+file:///home/jmeskill/Projects/github/iamruinous/nix-config";
    };
    ruinous-tty = {
      inherit flake;
      updateFlake = "git+file:///home/jmeskill/Projects/github/iamruinous/nix-config";
    };
    builder-tty = {
      inherit flake;
      updateFlake = "git+file:///home/jmeskill/Projects/github/iamruinous/nix-config";
    };
  };

  # make sure directories exist or vm boot will fail
  systemd.tmpfiles.rules = [
    "d /persistent/microvms/messy-tty/persistent 0770 root root -"
    "d /persistent/microvms/ruinous-tty/persistent 0770 root root -"
    "d /persistent/microvms/builder-tty/persistent 0770 root root -"
  ];
}
