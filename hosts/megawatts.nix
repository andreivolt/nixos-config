{ config, pkgs, ... }:

{
  imports =
    [
      ../drone.nix
      ../docker-nginx-proxy.nix
      ../docker-nginx-proxy-companion.nix
    ];

  boot.loader.grub.device = "/dev/vda";

  networking.extraHosts = ''
    127.0.0.1 avolt.net
  '';

  boot.kernel.sysctl = {
    "fs.file-max" = "524280";
  };

  networking.firewall.allowedTCPPorts = [
    80 443
    10000
    9999
  ];

  systemd.services.docker-nginx-proxy.enable = true;

  systemd.services.docker-nginx-proxy-companion.enable = false;

  services.dockerRegistry.enable = true;

  services.syncthing.openDefaultPorts = true;

  programs.mosh.enable = true;

  services.openssh.enable = true;
}
