{
  config.default.region = "eu-west-1";
  credentials.default = {
    aws_access_key_id     = builtins.getEnv "AWS_ACCESS_KEY_ID";
    aws_secret_access_key = builtins.getEnv "AWS_SECRET_ACCESS_KEY";
  };
}
