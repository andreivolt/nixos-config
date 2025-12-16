{
  pkgs,
  config,
  inputs,
  lib,
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
    ../../linux/zram.nix
    ./battery.nix
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

  # Prevent freezes during heavy builds - kill processes before swap thrashing
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    extraArgs = ["-g" "--prefer" "^(nix-daemon|cc1plus|clang|ld)$"];
  };

  home-manager.users.andrei = import ../../linux/home.nix {
    inherit config inputs;
  };
}
