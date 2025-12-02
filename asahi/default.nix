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

  # Enable notch area for full display utilization
  # This allows the bar to sit in the notch area like macOS
  boot.kernelParams = [ "apple_dcp.show_notch=1" ];

  # Lid switch behavior
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  home-manager.users.andrei = import ../linux/home.nix {
    inherit config inputs;
    # No extraPackagesFile - uses only base packages.nix (cross-platform)
  };
}
