{microvm, ...}: {
  imports = [microvm.host];
  microvm.autostart = ["blueprint"];
  microvm.vms = {
    blueprint = {
      # Specify from where to let `microvm -u` update later on
      updateFlake = "github:iamruinous/dotfiles/iamruinous/convert-blueprint?dir=nix-config";
    };
  };
}
