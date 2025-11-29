# Disk configuration for Asahi (Apple Silicon)
#
# The Asahi installer already created the partition layout:
# - EFI partition (shared with macOS stub)
# - Linux root partition
#
# We format the root as btrfs with subvolumes.
# EFI partition is mounted but NOT formatted (it has the bootloader chain).
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  options.asahi.rootPartition = lib.mkOption {
    type = lib.types.str;
    default = "/dev/nvme0n1p6";  # Adjust: run `lsblk` to find yours
    description = "The root partition created by Asahi installer";
  };

  options.asahi.efiPartition = lib.mkOption {
    type = lib.types.str;
    default = "/dev/nvme0n1p4";  # Adjust: the EFI stub partition
    description = "The EFI partition";
  };

  config = {
    # Use disko for the root partition only
    disko.devices = {
      disk = {
        root = {
          device = config.asahi.rootPartition;
          type = "disk";
          content = {
            type = "btrfs";
            extraArgs = [ "-L" "nixos" "-f" ];
            subvolumes = {
              "/@" = {
                mountpoint = "/";
                mountOptions = [ "noatime" "compress=zstd" ];
              };
              "/@nix" = {
                mountpoint = "/nix";
                mountOptions = [ "noatime" "compress=zstd" ];
              };
              "/@home" = {
                mountpoint = "/home";
                mountOptions = [ "noatime" "compress=zstd" ];
              };
              "/@log" = {
                mountpoint = "/var/log";
                mountOptions = [ "noatime" "compress=zstd" ];
              };
              "/@swap" = {
                mountpoint = "/swap";
                swap.swapfile.size = "4G";
              };
            };
          };
        };
      };
    };

    # Mount the existing EFI partition (not managed by disko)
    fileSystems."/boot" = {
      device = config.asahi.efiPartition;
      fsType = "vfat";
      options = [ "umask=0077" ];
    };

    # Boot loader
    boot.loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = false;
      efi.efiSysMountPoint = "/boot";
    };

    # BTRFS support
    boot.supportedFilesystems = [ "btrfs" ];

    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };

    environment.systemPackages = with pkgs; [
      btrfs-progs
      compsize
    ];
  };
}
