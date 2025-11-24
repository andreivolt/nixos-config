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
                  # Performance optimizations for SSD
                  extraOpenArgs = [
                    "--allow-discards"
                    "--perf-no_read_workqueue"
                    "--perf-no_write_workqueue"
                  ];
                  settings = {
                    # Ask for password on boot
                    allowDiscards = true;
                  };
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-L" "nixos" "-f" ];
                    subvolumes = {
                      "/root" = {
                        mountpoint = "/btrfs_root";
                        mountOptions = [ "subvol=root" "noatime" ];
                      };
                      "/nix" = {
                        mountpoint = "/nix";
                        mountOptions = [ "subvol=nix" "noatime" ];
                      };
                      "/persist" = {
                        mountpoint = "/persist";
                        mountOptions = [ "subvol=persist" "noatime" ];
                      };
                      "/home" = {
                        mountpoint = "/home";
                        mountOptions = [ "subvol=home" "noatime" ];
                      };
                      "/log" = {
                        mountpoint = "/var/log";
                        mountOptions = [ "subvol=log" "noatime" ];
                      };
                      "/swap" = {
                        mountpoint = "/swap";
                        swap.swapfile.size = "8G";  # Adjust based on RAM
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
      systemd-boot.configurationLimit = 10;  # Keep only 10 generations
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
      timeout = 3;  # Boot menu timeout in seconds
    };

    # Enable LUKS support in initrd
    boot.initrd.luks.devices."cryptroot" = {
      # Device will be determined by disko
      preLVM = true;
      allowDiscards = true;
    };

    # Kernel parameters for better SSD performance and power management
    boot.kernelParams = [
      "quiet"
      "splash"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    # Enable BTRFS support and tools
    boot.supportedFilesystems = [ "btrfs" ];

    # BTRFS maintenance
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };

    # Useful BTRFS tools
    environment.systemPackages = with pkgs; [
      btrfs-progs
      compsize  # Check compression ratio
    ];
  };
}