{
  uid = 4000;
  description = "Messy Agent";
  openssh.authorizedKeys.keyFiles = [./id_ed25519.pub ../jmeskill/id_ed25519.pub ../jmeskill/id_codey_ed25519.pub];
  extraGroups = ["wheel"]; # sudo
}
