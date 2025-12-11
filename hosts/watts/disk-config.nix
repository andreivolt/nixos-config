{ config, pkgs, lib, inputs, ... }:

let
  luksContent = import ../../shared/disk-common.nix;
in {
  imports = [ inputs.disko.nixosModules.disko ];

  options.nixos.diskDevice = lib.mkOption {
    type = lib.types.str;
    default = "/dev/nvme0n1";
  };

  config = {
    disko.devices.disk.main = {
      device = config.nixos.diskDevice;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          luks = {
            size = "100%";
            content = luksContent;
          };
        };
      };
    };

    boot.loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
      timeout = 3;
    };

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

    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" ];
    };
  };
}
