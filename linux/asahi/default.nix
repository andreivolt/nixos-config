# Generic Asahi Linux (Apple Silicon) configuration
# Works for all Apple Silicon Macs running Asahi Linux
{ lib, ... }: {
  imports = [
    ./battery.nix
    ./shutdown-sound-fix.nix
  ];

  hardware.asahi.setupAsahiSound = true;
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  hardware.asahi.extractPeripheralFirmware = true;

  # Apple Silicon uses m1n1 -> U-Boot -> systemd-boot, can't touch EFI vars
  boot.loader.efi.canTouchEfiVariables = false;

  # Apple NVMe SSDs are slow at flush, disable interval for better write perf
  boot.kernelParams = [ "nvme_apple.flush_interval=0" ];

  # Kernel looks for apple/ but firmware is in vendor/vendorfw/apple/
  system.activationScripts.appleFirmwareSymlink = lib.stringAfter [ "etc" ] ''
    if [ -d /lib/firmware/vendor/vendorfw/apple ] && [ ! -e /lib/firmware/apple ]; then
      ln -sf /lib/firmware/vendor/vendorfw/apple /lib/firmware/apple
    fi
  '';

  # Apple NVMe SSDs handle their own queueing
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ENV{DEVTYPE}=="disk", ATTR{queue/scheduler}="none"
  '';
}
