{ lib, inputs, ... }:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=2G" "mode=755" ];
  };

  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
      "/etc/nixos"
      "/var/lib/docker"
      "/var/lib/tailscale"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      { file = "/etc/nix/id_rsa"; parentDirectory = { mode = "u=rwx,g=rx,o=rx"; }; }
    ];
  };

  security.sudo.extraConfig = "Defaults lecture = never";
  programs.fuse.userAllowOther = true;
  nix.settings.build-dir = "/persist/nix-build";
  users.users.andrei.hashedPasswordFile = lib.mkDefault "/persist/passwords/andrei";
}
