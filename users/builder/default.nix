{
  uid = 4001;
  description = "Builder Bot - Automation Agent";
  openssh.authorizedKeys.keyFiles = [./id_ed25519.pub];
  extraGroups = ["wheel"]; # sudo for nix operations
}
