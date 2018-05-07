{ pkgs, ... }:

{
  imports = [
    ./docker-nginx-proxy.nix
  ];

  virtualisation.docker = {
    enable = true;
    extraOptions = "--experimental";
    autoPrune.enable = true;
  };

  # disable core dumps
  boot.kernel.sysctl."kernel.core_pattern" = "|/run/current-system/sw/bin/false";

  environment.systemPackages = with pkgs; [
    docker-compose-zsh-completions
    docker-machine
    docker_compose
  ];

  users.users.avo.extraGroups = [ "docker" ];
}
