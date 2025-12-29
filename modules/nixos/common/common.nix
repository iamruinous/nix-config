{
  flake,
  lib,
  pkgs,
  ...
}: {
  # imports shared.universal by default
  imports = [
    flake.sharedModules.universal
  ];

  # Set your time zone.
  time.timeZone = lib.mkDefault "America/Phoenix";
  # time.hardwareClockInLocalTime = true;

  # PATH configuration
  environment.localBinInPath = true;

  # Additional services
  services.locate.enable = true;

  # common packages
  environment.systemPackages = with pkgs; [
    pciutils
    usbutils
    isd
  ];

  # direnv integration
  programs.direnv = {
    enable = lib.mkDefault true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Fish configuration
  programs.fish.enable = lib.mkDefault true;

  # Passwordless sudo
  security.sudo.wheelNeedsPassword = false;

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

  # set default, agenix-rekey freaks out without this
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
