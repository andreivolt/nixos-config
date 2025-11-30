{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: {
  imports = [
    ../linux/base.nix
    ./disk-config.nix
    ./impermanence.nix
    ./users-persist.nix
    ../linux/mpv.nix
  ];

  networking.hostName = "asahi";
  system.stateVersion = "24.05";

  # Apple Silicon support
  hardware.asahi.setupAsahiSound = true;
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  hardware.asahi.extractPeripheralFirmware = true;

  # Fix firmware symlink for touchpad (tpmtfw) - kernel looks for apple/ but firmware is in vendor/vendorfw/apple/
  system.activationScripts.appleFirmwareSymlink = lib.stringAfter ["etc"] ''
    if [ -d /lib/firmware/vendor/vendorfw/apple ] && [ ! -e /lib/firmware/apple ]; then
      ln -sf /lib/firmware/vendor/vendorfw/apple /lib/firmware/apple
    fi
  '';

  # Boot - Apple Silicon uses m1n1 -> U-Boot -> systemd-boot
  boot.loader.efi.canTouchEfiVariables = false;

  # Lid switch behavior
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  # Keyboard backlight permissions
  services.udev.extraRules = ''
    SUBSYSTEM=="leds", ACTION=="add", KERNEL=="kbd_backlight", RUN+="${pkgs.coreutils}/bin/chgrp input /sys/class/leds/kbd_backlight/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/kbd_backlight/brightness"
  '';

  home-manager.users.andrei = import ../linux/home.nix {
    inherit config inputs;
    # Uses only base packages.nix (no extra packages for space-constrained install)
  };
}
