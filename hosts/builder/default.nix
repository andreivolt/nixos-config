{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./disk-config.nix
    ../../profiles/core.nix
    ../../linux/zram.nix
  ];

  boot.tmp.cleanOnBoot = true;
  boot.loader.grub.enable = true;
  hardware.bluetooth.enable = lib.mkForce false;

  networking = {
    hostName = "builder";
    useDHCP = false;
    useNetworkd = true;
    firewall.allowedTCPPorts = [ 22 5000 ];
  };

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "en* eth*";
      address = [ "217.182.172.36/24" ];
      gateway = [ "217.182.172.254" ];
      dns = [ "213.186.33.99" ];
    };
  };

  services.openssh.settings.PermitRootLogin = "prohibit-password";
  services.tailscale.extraUpFlags = lib.mkForce ["--login-server=https://hs.avolt.net"];

  nix.gc.options = lib.mkForce "--delete-older-than 90d";
  nix.settings.trusted-users = ["root" "andrei"];

  services.nix-serve = {
    enable = true;
    secretKeyFile = "/etc/nix-serve/cache-priv-key.pem";
  };

  users.users.andrei.hashedPasswordFile = lib.mkForce "/etc/passwords/andrei";

  home-manager.useGlobalPkgs = true;
  home-manager.users.andrei = {pkgs, ...}: {
    home.stateVersion = "25.05";
    home.enableNixpkgsReleaseCheck = false;
  };

  system.stateVersion = "25.05";
}
