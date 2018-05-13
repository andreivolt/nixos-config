{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ stack ];

  home-manager.users.avo
    .home.sessionVariables.STACK_ROOT = with config.home-manager.users.avo;
      "${xdg.dataHome}/stack";

  home-manager.users.avo
    .programs.zsh.shellAliases.stack =
      "${pkgs.stack}/bin/stack --nix";
}
