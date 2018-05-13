{
  home-manager.users.avo.programs.aws-cli = {
    enable = true;

    config.default.region = "eu-west-1";

    credentials.default = with (import ../private/credentials.nix).aws; {
      aws_access_key_id     = access_key_id;
      aws_secret_access_key = secret_access_key;
    };
  };
}
