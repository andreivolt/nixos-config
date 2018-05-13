{ config, pkgs, ... }:

{
  home-manager.users.avo
    .programs.zsh.shellAliases.pandora = with config.home-manager.users.avo;
      "${pkgs.avo-scripts}/bin/webapp pandora https://www.pandora.com/my-music";
}
