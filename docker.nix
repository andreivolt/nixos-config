{ pkgs, ... }:

{
  imports = [ ./docker-nginx-proxy.nix ];

  virtualisation.docker = {
    enable = true;
    extraOptions = "--experimental";
    autoPrune.enable = true;
  };

  environment.systemPackages = with pkgs; [
    docker-compose-zsh-completions
    docker-machine
    docker_compose
  ];

  users.users.avo.extraGroups = [ "docker" ];
}
