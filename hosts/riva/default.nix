{
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
    ../../linux/lan-mouse.nix
    ../../linux/mpv.nix
    ../../linux/rclone.nix
    # ../../linux/rclone-sync.nix
    ../../linux/zram.nix
    ../../linux/freebox.nix
    ../../linux/casting.nix
    ../../linux/monolith
    ./distributed-builds.nix
    ./earlyoom.nix
    ../../linux/asahi
    ../../linux/asahi/notch.nix
    ../../linux/asahi/j413-mic.nix
  ];

  networking.hostName = "riva";
  system.stateVersion = "24.05";

  # Lid switch behavior
  services.logind.settings.Login.HandleLidSwitchExternalPower = "lock";

  # Log crashes to journal but don't store dumps - saves disk space
  systemd.coredump.extraConfig = "Storage=none";

  # don't keep .drv files, rarely needed
  nix.settings.keep-derivations = false;

  home-manager.users.andrei = import ../../linux/home.nix {
    inherit config inputs;
  };
}
