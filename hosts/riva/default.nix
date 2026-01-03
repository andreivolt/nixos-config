{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../shared/sops.nix
    ../../shared/sops-home.nix
    ../../shared/ssh-client.nix
    ../../profiles/core.nix
    ../../profiles/workstation.nix
    ../../profiles/laptop.nix
    ./disk-config.nix
    ./impermanence.nix
    ../../shared/user-persist.nix
    ../../linux/lan-mouse.nix
    ../../linux/mpv.nix
    ../../linux/rclone.nix
    # ../../linux/rclone-sync.nix
    ../../linux/zram.nix
    ../../linux/monolith
    ./battery.nix
    ./distributed-builds.nix
  ];

  networking.hostName = "riva";
  system.stateVersion = "24.05";

  # Apple Silicon support
  hardware.asahi.setupAsahiSound = true;
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  hardware.asahi.extractPeripheralFirmware = true;

  # Set internal mic as default audio source (not headset jack)
  services.pipewire.wireplumber.extraConfig."50-asahi-mic-default" = {
    "wireplumber.settings" = {
      "default.audio.source" = "effect_output.j413-mic";
    };
  };

  # Fix firmware symlink for touchpad (tpmtfw) - kernel looks for apple/ but firmware is in vendor/vendorfw/apple/
  system.activationScripts.appleFirmwareSymlink = lib.stringAfter ["etc"] ''
    if [ -d /lib/firmware/vendor/vendorfw/apple ] && [ ! -e /lib/firmware/apple ]; then
      ln -sf /lib/firmware/vendor/vendorfw/apple /lib/firmware/apple
    fi
  '';

  # Boot - Apple Silicon uses m1n1 -> U-Boot -> systemd-boot
  boot.loader.efi.canTouchEfiVariables = false;

  boot.kernelParams = [
    "apple_dcp.show_notch=1"       # show bar in notch area like macOS
    "nvme_apple.flush_interval=0"  # Apple SSDs are slow at flush, this speeds up writes
  ];

  # Lid switch behavior
  services.logind.settings.Login.HandleLidSwitchExternalPower = "lock";

  # Log crashes to journal but don't store dumps - saves disk space
  systemd.coredump.extraConfig = "Storage=none";

  # don't keep .drv files, rarely needed
  nix.settings.keep-derivations = false;

  # Prevent freezes during heavy builds - kill processes before swap thrashing
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    extraArgs = ["--prefer" "^(nix-daemon|cc1plus|clang|ld)$"];
  };

  # NVMe scheduler - use none, hardware handles queueing
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
  '';

  home-manager.users.andrei = import ../../linux/home.nix {
    inherit config inputs;
  };
}
