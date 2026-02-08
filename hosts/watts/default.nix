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
    ./touchscreen.nix
    ./hypr-autorotate.nix
    ./insync.nix
    ../../linux/zswap.nix
    ../../linux/glsl-screensaver.nix
    ./ddc.nix
    ./v4l2loopback.nix
    ./distributed-builds.nix
    ./throttled.nix
    ./screensaver.nix
    ../../linux/intel
  ];

  networking.hostName = "watts";
  system.stateVersion = "23.11";

  # XanMod kernel - optimized for desktop/low-latency workloads
  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  # Configure the disk device for this machine
  nixos.diskDevice = "/dev/nvme0n1";

  home-manager.users.andrei = import ../../linux/home.nix {
    inherit config inputs;
  };
}
