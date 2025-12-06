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
    ./battery-monitor.nix
    ./fkey-remap.nix
    ./fingerprint.nix
    ../../linux/ipv6-disable.nix
    ../../linux/lan-mouse.nix
    ../../linux/libvirt.nix
    ../../linux/nixos-rebuild-summary.nix
    ./roon-server.nix
    ./thinkpad.nix
    ../../linux/touchscreen.nix
  ];

  networking.hostName = "watts";
  system.stateVersion = "23.11";

  # Configure the disk device for this machine
  nixos.diskDevice = "/dev/nvme0n1";

  home-manager.users.andrei = import ../../linux/home.nix {
    inherit config inputs;
    # extraPackagesFile removed - now handled by platform conditionals in main packages.nix
  };
}
