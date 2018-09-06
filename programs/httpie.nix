{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ httpie ];

  environment.variables.HTTPIE_CONFIG_DIR = "/etc/httpie";

  environment.etc."httpie/config.json".text = lib.generators.toJSON {} {
    default_options = [
      "--pretty" "format"
      "--session" "default"
    ];
  };
}
