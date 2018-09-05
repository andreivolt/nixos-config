{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ httpie ];

  home-manager.users.avo
    .home.sessionVariables.HTTPIE_CONFIG_DIR = with config.home-manager.users.avo.xdg;
      "${configHome}/httpie";

  home-manager.users.avo
    .xdg.configFile."httpie/config.json".text = lib.generators.toJSON {} {
      default_options = [
        "--pretty" "format"
        "--session" "default"
      ];
  };
}
