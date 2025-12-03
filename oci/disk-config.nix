# Disk configuration for OCI (Oracle Cloud Infrastructure)
#
# Simple btrfs layout with impermanence support.
# No LUKS since OCI provides infrastructure-level security.
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.oci.diskDevice = lib.mkOption {
    type = lib.types.str;
    default = "/dev/sda";
    description = "The disk device to use for the system installation";
  };

  config = {
    disko.devices = {
      disk = {
        main = {
          device = config.oci.diskDevice;
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
              swap = {
                size = "2G";
                content = {
                  type = "swap";
                  randomEncryption = true;
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-L" "nixos" "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/btrfs_root";
                      mountOptions = [ "noatime" "compress=zstd" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "noatime" "compress=zstd" ];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "noatime" "compress=zstd" ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "noatime" "compress=zstd" ];
                    };
                    "/log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "noatime" "compress=zstd" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

    # Boot loader - UEFI with systemd-boot
    boot.loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
    };

    # BTRFS support
    boot.supportedFilesystems = [ "btrfs" ];

    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/btrfs_root" ];
    };

    environment.systemPackages = with pkgs; [
      btrfs-progs
    ];
  };
}
