let credentials = import ../credentials.nix;
in {
  config.default.region = "eu-west-1";
  credentials.default = with credentials.aws; {
    aws_access_key_id     = access_key_id;
    aws_secret_access_key = secret_access_key;
  };
}
