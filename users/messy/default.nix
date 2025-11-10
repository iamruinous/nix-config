{
  uid = 4000;
  description = "Messy Agent";
  # openssh.authorizedKeys.keyFiles = [./id_ed25519.pub];
  extraGroups = ["wheel"]; # sudo
}
