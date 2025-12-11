{ config, pkgs, lib, inputs, ... }:

let
  luksContent = import ../../shared/disk-common.nix;
in {
  imports = [ inputs.disko.nixosModules.disko ];

  options.asahi.rootPartition = lib.mkOption {
    type = lib.types.str;
    default = "/dev/nvme0n1p6";
  };

  options.asahi.efiPartition = lib.mkOption {
    type = lib.types.str;
    default = "/dev/nvme0n1p4";
  };

  config = {
    disko.devices.disk.root = {
      device = config.asahi.rootPartition;
      type = "disk";
      content = luksContent;
    };

    fileSystems."/boot" = {
      device = config.asahi.efiPartition;
      fsType = "vfat";
      options = [ "umask=0077" ];
    };

    boot.loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = false;
      efi.efiSysMountPoint = "/boot";
    };

    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/btrfs_root" ];
    };
  };
}
