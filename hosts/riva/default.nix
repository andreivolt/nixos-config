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
    ../../profiles/core.nix
    ../../profiles/workstation.nix
    ./disk-config.nix
    ./impermanence.nix
    ./users-persist.nix
    ../../linux/lan-mouse.nix
    ../../linux/mpv.nix
    ../../linux/rclone.nix
  ];

  networking.hostName = "riva";
  system.stateVersion = "24.05";

  # Auto-switch power profiles (works with Asahi's apple-cpufreq driver)
  services.power-profiles-daemon.enable = true;

  # Prefer keeping data in RAM over swapping (16GB is plenty)
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Allow CPU to idle properly (default 1024 prevents low-power states)
  boot.kernel.sysctl."kernel.sched_util_clamp_min" = 128;

  # More responsive I/O writeback (reduces UI stutter during large file ops)
  boot.kernel.sysctl."vm.dirty_ratio" = 10;
  boot.kernel.sysctl."vm.dirty_background_ratio" = 5;

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

  # Enable notch area for full display utilization
  # This allows the bar to sit in the notch area like macOS
  boot.kernelParams = [ "apple_dcp.show_notch=1" ];

  # Lid switch behavior
  services.logind.settings.Login.HandleLidSwitchExternalPower = "lock";

  home-manager.users.andrei = import ../../linux/home.nix {
    inherit config inputs;
  };
}
