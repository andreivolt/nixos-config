{ pkgs, ... }:

{
  imports = [ ./docker-nginx-proxy.nix ];

  environment.systemPackages = with pkgs; [
    docker-compose-zsh-completions
    docker-machine
    docker_compose
  ];

  users.users.avo.extraGroups = [ "docker" ];

  virtualisation.docker = {
    enable = true;
    extraOptions = "--experimental";
    autoPrune.enable = true;
  };
}
