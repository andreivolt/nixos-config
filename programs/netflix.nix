{ config, pkgs, ... }:

{
  home-manager.users.avo
    .programs.zsh.shellAliases.netflix = with config.home-manager.users.avo;
      "${pkgs.avo-scripts}/bin/webapp netflix https://www.netflix.com";
}
