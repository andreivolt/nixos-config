{
  pkgs,
  config,
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
    ../../linux/adb.nix
    ./fkey-remap.nix
    ./fingerprint.nix
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
    ../../linux/wol.nix
    ../../linux/glsl-screensaver.nix
  ];

  # GLSL screensaver - plasma shader, 10min idle, main monitor only
  services.glsl-screensaver = {
    enable = true;
    visual = "plasma";
    timeout = 600;  # 10 minutes
    monitor = "eDP-1";  # internal display only
  };

  # On-demand screensaver command
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "screensaver" ''
      # Save current focused monitor and window
      PREV_MON=$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
      PREV_ADDR=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.address')

      # Launch screensaver in background
      ${pkgs.callPackage ../../pkgs/screensaver {}}/bin/screensaver \
        --fps 60 --shader plasma --monitor eDP-1 "$@" &
      PID=$!

      # Kill screensaver on Ctrl+C
      trap "kill $PID 2>/dev/null" INT TERM

      # Restore focus after brief delay
      sleep 0.2
      ${pkgs.hyprland}/bin/hyprctl dispatch focusmonitor "$PREV_MON" >/dev/null
      [ -n "$PREV_ADDR" ] && [ "$PREV_ADDR" != "null" ] && \
        ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "address:$PREV_ADDR" >/dev/null

      # Wait for screensaver to exit
      wait $PID
    '')
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

  # Distribute hardware interrupts across CPUs (reduces CPU0 overload, Intel-specific)
  services.irqbalance.enable = true;

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
