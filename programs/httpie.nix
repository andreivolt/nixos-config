{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ httpie ];

  environment.variables.HTTPIE_CONFIG_DIR = "~/.config/httpie";

  home-manager.users.avo
    .xdg.configFile."httpie/config.json".text = lib.generators.toJSON {} {
      default_options = [
        "--pretty" "format"
        "--session" "default"
      ];
  };
}
