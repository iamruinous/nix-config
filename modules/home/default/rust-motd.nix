# rust-motd configuration for login info display
# Works on both NixOS and Darwin via home-manager
{
  lib,
  pkgs,
  config,
  osConfig ? null,
  ...
}: let
  cfg = config.ruinous.rust-motd;

  # Filter real filesystems from NixOS config (exclude pseudo-filesystems and swap)
  excludedFsTypes = ["none" "tmpfs" "ramfs" "devtmpfs" "proc" "sysfs" "devpts" "cgroup" "cgroup2" "overlay" "autofs" "efivarfs" "securityfs" "debugfs" "configfs" "fusectl" "mqueue" "hugetlbfs" "pstore" "binfmt_misc" "swap"];

  # Get filesystems from osConfig if available, otherwise empty
  nixosFilesystems =
    if osConfig != null && osConfig ? fileSystems
    then
      lib.filterAttrs (
        name: fs:
          !(builtins.elem fs.fsType excludedFsTypes)
          && fs.device != "none"
          && !(lib.hasPrefix "/nix/" name) # Skip nix store bind mounts
          && name != "/nix/store" # Skip nix store
          && !(lib.hasPrefix "/dev" name) # Skip /dev mounts
          && !(lib.hasPrefix "/run" name) # Skip /run mounts
          && !(lib.hasPrefix "/sys" name) # Skip /sys mounts
          && !(lib.hasInfix ".swapvol" name) # Skip btrfs swap subvolumes
          && !(lib.hasInfix "partition-root" name) # Skip partition-root mounts
      )
      osConfig.fileSystems
    else {};

  # Convert to list of {name, mountPoint} for config generation
  # Use the mount point as the display name (cleaned up)
  autoFilesystems =
    lib.mapAttrsToList (
      mountPoint: fs: {
        name =
          if mountPoint == "/"
          then "root"
          else lib.removePrefix "/" (lib.replaceStrings ["/"] ["-"] mountPoint);
        inherit mountPoint;
      }
    )
    nixosFilesystems;

  # Merge auto-detected with manually specified filesystems
  allFilesystems = cfg.filesystems ++ autoFilesystems;

  # Generate filesystem entries for KDL config
  filesystemEntries =
    lib.concatMapStringsSep "\n" (
      fs: ''filesystem name="${fs.name}" mount-point="${fs.mountPoint}"''
    )
    allFilesystems;

  # Get the current username for last-login
  username = config.home.username;

  # Generate the complete KDL config
  configKdl = pkgs.writeText "rust-motd-config.kdl" ''
    global {
      version "1.0"
      progress-full-character "━"
      progress-empty-character "─"
      progress-prefix "["
      progress-suffix "]"
    }

    components {
      uptime prefix="⏱️ "
      memory swap-pos="none"
      filesystems {
    ${filesystemEntries}
      }
      last-login {
        user username="${username}" num-logins=3
      }
    }
  '';
in {
  options.ruinous.rust-motd = {
    enable = lib.mkEnableOption "rust-motd system info display on login";

    filesystems = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Display name for the filesystem";
            example = "home";
          };
          mountPoint = lib.mkOption {
            type = lib.types.str;
            description = "Mount point path";
            example = "/home";
          };
        };
      });
      default = [];
      description = ''
        Additional filesystems to display. These are merged with
        auto-detected filesystems from NixOS config.
      '';
      example = [
        {
          name = "data";
          mountPoint = "/data";
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.rust-motd];

    # Use dynamically generated KDL config
    xdg.configFile."rust-motd/config.kdl".source = configKdl;
  };
}
