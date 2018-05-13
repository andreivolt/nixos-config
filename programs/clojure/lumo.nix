{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ lumo ];

  home-manager.users.avo
    .programs.zsh.shellAliases.lumo = with config.home-manager.users.avo;
      "${pkgs.lumo}/bin/lumo --cache ${xdg.cacheHome}/lumo";
}
