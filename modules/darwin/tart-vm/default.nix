# ruinous.tart-vm - Tart VM management for macOS
#
# Provides declarative configuration for Tart virtual machines on macOS.
# Tart uses Apple's Virtualization.Framework for native ARM64 macOS VMs.
#
# Example usage:
#   ruinous.tart-vm = {
#     enable = true;
#     vms.my-vm = {
#       enable = true;
#       cpu = 4;
#       memory = 8192;
#       autostart = true;
#       headless = true;
#       sharedDirs = [ "/Users/me/shared" ];
#     };
#   };
#
# Note: VMs must be created manually with `tart clone` or `tart create` first.
# This module only manages VM configuration and autostart services.
#
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.ruinous.tart-vm;

  # VM configuration submodule
  vmOpts = {name, ...}: {
    options = {
      enable = mkEnableOption "this Tart VM";

      cpu = mkOption {
        type = types.int;
        default = 2;
        description = "Number of CPU cores to allocate to the VM.";
      };

      memory = mkOption {
        type = types.int;
        default = 4096;
        description = "Amount of memory in MB to allocate to the VM.";
      };

      display = mkOption {
        type = types.str;
        default = "1024x768";
        description = "Display resolution in WxH format (e.g., '1920x1080').";
      };

      autostart = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to automatically start this VM at login via launchd.";
      };

      headless = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to run the VM without graphics (--no-graphics flag).";
      };

      sharedDirs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          List of host directories to share with the VM.
          Each directory will be passed as --dir to tart run.
        '';
        example = ["/Users/me/shared" "/tmp/vm-data"];
      };

      netBridged = mkOption {
        type = types.nullOr types.str;
        default = "en0";
        description = ''
          Network interface to bridge to for DHCP from router.
          Use "en0" for Ethernet, "Wi-Fi" for wireless.
          Set to null to use default shared (NAT) networking.
        '';
        example = "Wi-Fi";
      };
    };
  };

  # Generate launchd agent for a VM
  mkLaunchdAgent = name: vmCfg: let
    # Build the tart run command arguments
    baseArgs = ["${pkgs.tart}/bin/tart" "run" name];
    graphicsArgs =
      if vmCfg.headless
      then ["--no-graphics"]
      else [];
    dirArgs = concatMap (dir: ["--dir" dir]) vmCfg.sharedDirs;
    netArgs =
      if vmCfg.netBridged != null
      then ["--net-bridged=${vmCfg.netBridged}"]
      else [];
    allArgs = baseArgs ++ graphicsArgs ++ netArgs ++ dirArgs;

    # Log paths
    logDir = "/tmp/tart-vm";
  in {
    enable = vmCfg.enable && vmCfg.autostart;
    config = {
      ProgramArguments = allArgs;
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
      };
      StandardOutPath = "${logDir}/${name}-stdout.log";
      StandardErrorPath = "${logDir}/${name}-stderr.log";
    };
  };

  # Filter to only enabled VMs with autostart
  enabledAutostartVms = filterAttrs (_: vm: vm.enable && vm.autostart) cfg.vms;
in {
  options.ruinous.tart-vm = {
    enable = mkEnableOption "Tart VM management";

    vms = mkOption {
      type = types.attrsOf (types.submodule vmOpts);
      default = {};
      description = ''
        Attribute set of Tart VM configurations.
        Each VM is identified by its name (must match the Tart VM name).
      '';
      example = literalExpression ''
        {
          macos-dev = {
            enable = true;
            cpu = 4;
            memory = 8192;
            autostart = true;
            headless = true;
          };
          macos-test = {
            enable = true;
            cpu = 2;
            memory = 4096;
            autostart = false;
            headless = false;
            display = "1920x1080";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Ensure tart is available
    environment.systemPackages = [pkgs.tart];

    # Generate launchd agents for each autostart VM
    launchd.user.agents =
      mapAttrs'
      (name: vmCfg:
        nameValuePair "com.ruinous.tart-vm.${name}" (mkLaunchdAgent name vmCfg))
      enabledAutostartVms;
  };
}
