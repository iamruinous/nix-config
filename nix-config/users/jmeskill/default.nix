{
  uid = 1000;
  description = "Jade Meskill";
  openssh.authorizedKeys.keyFiles = [./id_ed25519.pub];
  extraGroups = ["wheel"]; # sudo
}
