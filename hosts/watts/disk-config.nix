{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  # Option to set the disk device per machine
  options.nixos.diskDevice = lib.mkOption {
    type = lib.types.str;
    default = "/dev/nvme0n1";  # Common default for modern laptops
    description = "The disk device to use for the system installation";
  };

  config = {
    # Disko configuration with LUKS and Btrfs
    disko.devices = {
      disk = {
        main = {
          device = config.nixos.diskDevice;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "512M";
                type = "EF00";  # EFI System Partition
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "cryptroot";
                  extraOpenArgs = [
                    "--allow-discards"
                    "--perf-no_read_workqueue"
                    "--perf-no_write_workqueue"
                  ];
                  settings.allowDiscards = true;
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-L" "nixos" "-f" ];
                    subvolumes = {
                      "/root" = {
                        mountpoint = "/";
                        mountOptions = [ "noatime" "compress=zstd" ];
                      };
                      "/nix" = {
                        mountpoint = "/nix";
                        mountOptions = [ "noatime" ];
                      };
                      "/persist" = {
                        mountpoint = "/persist";
                        mountOptions = [ "noatime" ];
                      };
                      "/home" = {
                        mountpoint = "/home";
                        mountOptions = [ "noatime" ];
                      };
                      "/log" = {
                        mountpoint = "/var/log";
                        mountOptions = [ "noatime" ];
                      };
                      "/swap" = {
                        mountpoint = "/swap";
                        swap.swapfile.size = "8G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

    # Boot loader configuration
    boot.loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
      timeout = 3;
    };

    # Kernel parameters for better SSD performance and power management
    boot.kernelParams = [
      "quiet"
      "splash"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      # Use TSC for faster timekeeping (Intel has reliable TSC)
      "clocksource=tsc"
      "tsc=reliable"
    ];

    # BTRFS maintenance
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };

    fileSystems."/btrfs_root" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=/" "noatime" "nofail" ];
    };

    btrfsWipe.rootSubvolume = "root";
    btrfsWipe.oldRootsDirectory = "old_roots";
  };
}