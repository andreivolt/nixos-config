{ config, pkgs, ... }:

{
  imports =
    [
      ./docker-gc.nix
    ];

  virtualisation.docker.enable = true;

  users.users.avo.extraGroups = [ "docker" ];

  systemd.services.docker-gc.enable = true;
}
