{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ gnupg ];

  home-manager.users.avo
    .home.sessionVariables.GNUPGHOME = with config.home-manager.users.avo;
      "${xdg.configHome}/gnupg";
}
