{ pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # disable core dumps
  boot.kernel.sysctl."kernel.core_pattern" = "|/run/current-system/sw/bin/false";

  environment.systemPackages = with pkgs; [
    docker-machine
    docker_compose
  ];

  users.users.avo.extraGroups = [ "docker" ];
}
