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
    ./roon-idle-inhibit.nix
    ./dac-toggle.nix
    ./intel-vaapi.nix
    ./touchscreen.nix
    ./hypr-autorotate.nix
    ./insync.nix
    ../../linux/zram.nix
    ../../linux/glsl-screensaver.nix
    ./ddc.nix
    ./v4l2loopback.nix
    ./distributed-builds.nix
    ./throttled.nix
  ];

  # GLSL screensaver - plasma shader, 10min idle, main monitor only
  services.glsl-screensaver = {
    enable = true;
    visual = "plasma";
    timeout = 600;  # 10 minutes
    monitor = "eDP-1";  # internal display only
  };

  networking.hostName = "watts";
  system.stateVersion = "23.11";

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
