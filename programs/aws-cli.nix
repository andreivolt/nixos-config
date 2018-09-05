{ config, lib, pkgs, ... }:

let
  config_file = pkgs.writeText "aws_config_file" (lib.generators.toINI {} {
    default.region = "eu-west-1";
  });

  shared_credentials_file = pkgs.writeText "aws_shared_credentials_file" (lib.generators.toINI {} {
    default = with (import ../credentials.nix).aws; {
      aws_access_key_id = access_key_id;
      aws_secret_access_key = secret_access_key;
    };
  });

in {
  environment.systemPackages = with pkgs; [ awscli ];

  environment.variables = {
    AWS_CONFIG_FILE = "${config_file}";
    AWS_SHARED_CREDENTIALS_FILE = "${shared_credentials_file}";
  };
}
