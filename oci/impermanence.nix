{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  # Tmpfs setup for root (impermanent root)
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=1G" "mode=755" ];
  };

  # Mark important filesystems as needed for boot
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;

  # Impermanence configuration
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/headscale"
      "/var/lib/tailscale"
      "/var/lib/nixos"
      "/var/lib/acme"
      "/var/lib/systemd/coredump"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  # Security configuration to prevent sudo lecture after each reboot
  security.sudo.extraConfig = ''
    # rollback results in sudo lectures after each reboot
    Defaults lecture = never
  '';

  # This is required for the impermanence setup
  programs.fuse.userAllowOther = true;

  # Ensure andrei user's password file exists (if using passwords)
  # users.users.andrei = {
  #   hashedPasswordFile = "/persist/passwords/andrei";
  # };
}
