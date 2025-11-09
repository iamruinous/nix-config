{
  lib,
  config,
  pkgs,
  flake,
  ...
}: {
  imports = [
    flake.nixosModules.common
  ];

  # Register flake inputs for nix commands
  # nix.registry = lib.mapAttrs (_: flake: {inherit flake;}) (lib.filterAttrs (_: lib.isType "flake") inputs);

  nix.optimise.automatic = lib.mkDefault true;

  # Add inputs to legacy channels
  nix.nixPath = ["/etc/nix/path"];
  environment.etc =
    lib.mapAttrs'
    (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  # Networking
  networking.networkmanager.enable = lib.mkDefault true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = lib.mkDefault false;

  # Set your time zone.
  time.timeZone = "America/Phoenix";
  time.hardwareClockInLocalTime = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # PATH configuration
  environment.localBinInPath = true;

  # Fish configuration
  programs.fish.enable = true;

  # Additional services
  services.locate.enable = true;

  # OpenSSH daemon
  services.openssh.enable = lib.mkDefault true;
  services.openssh.extraConfig = ''
    Match User jmeskill
          AllowAgentForwarding yes
          AllowTcpForwarding yes
          PermitTTY yes
          PermitTunnel yes
          X11Forwarding yes
    Match All
  ''; # TODO: generalize user

  # direnv integration
  programs.direnv = {
    enable = lib.mkDefault true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Neovim text editor configuration
  programs.neovim = {
    enable = lib.mkDefault true;
    package = pkgs.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  environment.systemPackages = with pkgs; [
    btop
    pciutils
    isd
  ];
}
