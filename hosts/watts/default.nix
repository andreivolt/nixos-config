{
  pkgs,
  config,
  inputs,
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
    ../../linux/mpv.nix
    ../../linux/adb.nix
    ./fkey-remap.nix
    ./fingerprint.nix
    ../../linux/ipv6-disable.nix
    ../../linux/lan-mouse.nix
    ../../linux/libvirt.nix
    ../../linux/nixos-rebuild-summary.nix
    ./roon-server.nix
    ./dac-toggle.nix
    ./intel-vaapi.nix
    ../../linux/touchscreen.nix
    ../../linux/hypr-autorotate.nix
    ./insync.nix
    ../../linux/zram.nix
    ../../linux/ddc.nix
  ];

  networking.hostName = "watts";
  system.stateVersion = "23.11";

  # Fix ThinkPad BD PROCHOT throttling bug + undervolt for cooler temps
  # https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Carbon_(Gen_6)#Throttling_fix
  services.throttled = {
    enable = true;
    extraConfig = ''
      [GENERAL]
      Enabled: True
      Sysfs_Power_Path: /sys/class/power_supply/AC*/online
      Autoreload: True

      [BATTERY]
      Update_Rate_s: 30
      PL1_Tdp_W: 15
      PL1_Duration_s: 28
      PL2_Tdp_W: 20
      PL2_Duration_S: 0.002
      Trip_Temp_C: 85
      cTDP: 0
      Disable_BDPROCHOT: False

      [AC]
      Update_Rate_s: 5
      PL1_Tdp_W: 25
      PL1_Duration_s: 28
      PL2_Tdp_W: 29
      PL2_Duration_S: 0.002
      Trip_Temp_C: 95
      HWP_Mode: True
      cTDP: 0
      Disable_BDPROCHOT: False

      [UNDERVOLT.BATTERY]
      # Tested stable
      CORE: -80
      GPU: -50
      CACHE: -80
      UNCORE: -50
      ANALOGIO: 0

      [UNDERVOLT.AC]
      # -100mV caused freeze during rebuild, -90mV as compromise
      CORE: -90
      GPU: -60
      CACHE: -90
      UNCORE: -60
      ANALOGIO: 0
    '';
  };

  # Auto-switch power profiles based on AC/battery
  services.power-profiles-daemon.enable = true;

  # Distribute hardware interrupts across CPUs (reduces CPU0 overload)
  services.irqbalance.enable = true;

  # Allow CPU to idle properly (default 1024 prevents low-power states)
  boot.kernel.sysctl."kernel.sched_util_clamp_min" = 128;

  # More responsive I/O writeback (reduces UI stutter during large file ops)
  boot.kernel.sysctl."vm.dirty_ratio" = 10;
  boot.kernel.sysctl."vm.dirty_background_ratio" = 5;

  # XanMod kernel - optimized for desktop/low-latency workloads
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  # Update Intel microcode for complete Spectre/Meltdown/GDS mitigations
  hardware.cpu.intel.updateMicrocode = true;

  # Configure the disk device for this machine
  nixos.diskDevice = "/dev/nvme0n1";

  home-manager.users.andrei = import ../../linux/home.nix {
    inherit config inputs;
  };
}
