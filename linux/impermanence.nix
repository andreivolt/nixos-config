{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  # Tmpfs setup for root (impermanent root)
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=3G" "mode=755" ];
  };

  # Note: /home is NOT on tmpfs - it's a persistent Btrfs subvolume
  # configured in disk-config.nix

  # Mark important filesystems as needed for boot
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;

  # Impermanence configuration
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/systemd/backlight"
      "/etc/NetworkManager/system-connections"
      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
      "/etc/nixos"
      "/var/lib/docker"
      "/var/lib/libvirt"
      "/var/lib/lxd"
      "/var/lib/machines"
      "/var/lib/tailscale"
      { directory = "/var/lib/roon-server"; user = "roon-server"; group = "roon-server"; mode = "u=rwx,g=rx,o="; }
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      { file = "/etc/nix/id_rsa"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
    ];
    # No user-specific persistence needed since /home is already persistent
    # users.andrei = { };
  };

  # Security configuration to prevent sudo lecture after each reboot
  security.sudo.extraConfig = ''
    # rollback results in sudo lectures after each reboot
    Defaults lecture = never
  '';

  # This is required for the impermanence setup
  programs.fuse.userAllowOther = true;

  # Use persistent storage for Nix builds instead of tmpfs
  nix.settings.build-dir = "/persist/nix-build";

  # Ensure andrei user's password file exists
  users.users.andrei = {
    hashedPasswordFile = lib.mkDefault "/persist/passwords/andrei";
  };
}