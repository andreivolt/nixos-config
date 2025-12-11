{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    ../../profiles/core.nix
    ../../profiles/workstation.nix
    ./disk-config.nix
    ./impermanence.nix
    ./users-persist.nix
    ./insync.nix
    ../../linux/mpv.nix
    ../../linux/adb.nix
    ./fkey-remap.nix
    ./fingerprint.nix
    ../../linux/ipv6-disable.nix
    ../../linux/lan-mouse.nix
    ../../linux/libvirt.nix
    ../../linux/nixos-rebuild-summary.nix
    ./roon-server.nix
    ./intel-vaapi.nix
    ../../linux/touchscreen.nix
  ];

  networking.hostName = "watts";
  system.stateVersion = "23.11";

  # Fix ThinkPad BD PROCHOT throttling bug
  # https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Carbon_(Gen_6)#Throttling_fix
  services.throttled.enable = true;

  # Auto-switch power profiles based on AC/battery
  services.power-profiles-daemon.enable = true;

  # Prefer keeping data in RAM over swapping (16GB is plenty)
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Allow CPU to idle properly (default 1024 prevents low-power states)
  boot.kernel.sysctl."kernel.sched_util_clamp_min" = 128;

  # XanMod kernel - optimized for desktop/low-latency workloads
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  # Update Intel microcode for complete Spectre/Meltdown/GDS mitigations
  hardware.cpu.intel.updateMicrocode = true;

  # Configure the disk device for this machine
  nixos.diskDevice = "/dev/nvme0n1";

  home-manager.users.andrei = import ../../linux/home.nix {
    inherit config inputs;
    # extraPackagesFile removed - now handled by platform conditionals in main packages.nix
  };
}
