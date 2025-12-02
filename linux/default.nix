{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    ./base.nix
    ./disk-config.nix
    ./impermanence.nix
    ./users-persist.nix
    ./insync.nix
    ./mpv.nix
    ./adb.nix
    ./battery-monitor.nix
    ./fkey-remap.nix
    ./fingerprint.nix
    ./ipv6-disable.nix
    ./lan-mouse.nix
    ./libvirt.nix
    ./nixos-rebuild-summary.nix
    ./roon-server.nix
    ./thinkpad.nix
    ./touchscreen.nix
    # ./wayvnc.nix
  ];

  networking.hostName = "watts";
  system.stateVersion = "23.11";

  # Configure the disk device for this machine
  nixos.diskDevice = "/dev/nvme0n1";

  home-manager.users.andrei = import ./home.nix {
    inherit config inputs;
    extraPackagesFile = "${inputs.self}/linux/packages-extra.nix";
  };
}
