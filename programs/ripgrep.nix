{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ ripgrep ];

  home-manager.users.avo
    .home.sessionVariables.RIPGREP_CONFIG_PATH = with config.home-manager.users.avo;
      "${xdg.configHome}/ripgrep/config";

  home-manager.users.avo
    .xdg.configFile."ripgrep/config".text = ''
      --smart-case
      --colors=match:bg:white
      --colors=match:fg:black
    '';
}
