{
  flake,
  perSystem,
  config,
  ...
}: {
  imports = [
    flake.inputs.agenix.nixosModules.default
    flake.inputs.agenix-rekey.nixosModules.default
  ];

  environment.systemPackages = [
    perSystem.agenix.default
  ];

  # agenix-rekey configuration for automatic secret management
  age.rekey = {
    hostPubkey = flake + /hosts/${config.networking.hostName}/ssh_host_ed25519_key.pub;
    masterIdentities = [(flake + /secrets/master-keys/master.pub)];
    storageMode = "local";
    localStorageDir = flake + "/secrets/rekeyed/${config.networking.hostName}";
  };
}
