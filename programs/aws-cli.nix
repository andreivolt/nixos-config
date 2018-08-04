{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ awscli ];

  home-manager.users.avo
    .home.sessionVariables = with config.home-manager.users.avo.xdg; {
      AWS_CONFIG_FILE             = "${configHome}/aws/config";
      AWS_SHARED_CREDENTIALS_FILE = "${configHome}/aws/credentials";
    };

  home-manager.users.avo
    .xdg.configFile = {
      "aws/config".text = lib.generators.toINI {} {
        default.region = "eu-west-1";
      };

      "aws/credentials".text = lib.generators.toINI {} {
        default = with (import ../private/credentials.nix).aws; {
          aws_access_key_id     = access_key_id;
          aws_secret_access_key = secret_access_key;
        };
      };
    };
}
