{pkgs, ...}: {
  # The configuration for the MicroVM.
  # Multiple definitions will be merged as expected.
  system.stateVersion = "25.05";

  networking.hostName = "messytty";

  users.users.root.password = "password";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm iamruinous@ruinous.social"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHrfqbC3NHGjwLhV4qoBCWZ44DU7dfyhUJJ83XCD1LD messy@messytty"
  ];

  users.users.messy = {
    password = "password";
    extraGroups = ["wheel"];
    group = "users";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8rjXP/sjewv6kM1aTtNWkVZKJpZvIAXIRqL81IyEsm iamruinous@ruinous.social"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIHrfqbC3NHGjwLhV4qoBCWZ44DU7dfyhUJJ83XCD1LD messy@messytty"
    ];
  };

  microvm = {
    mem = 2047;
    vcpu = 2;
    hypervisor = "qemu";
    forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
    ];

    interfaces = [
      # {
      #   type = "macvtap";
      #   link = "enp2s0";
      #   id = "mv-eth0";
      #   mac = "02:00:00:00:00:01";
      # }
      {
        type = "user";
        id = "vm-eth0";
        mac = "02:00:00:00:00:01";
      }
    ];

    # It is highly recommended to share the host's nix-store
    # with the VMs to prevent building huge images.
    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    # startWhenNeeded = true;
    # listenAddresses = [];
    # settings = {
    #   PermitRootLogin = "yes";
    #   PasswordAuthentication = true;
    #   PermitEmptyPasswords = true;
    #   UsePAM = false;
    # };
  };

  environment.systemPackages = with pkgs; [
    tmux
  ];
  # systemd.sockets.sshd = {
  #   socketConfig = {
  #     ListenStream = [
  #       "vsock:1337:22"
  #     ];
  #   };
  # };
}
