{ config, ... }:

{
  environment.variables = {
    PAGER = "less";
    LESSHISTFILE = "~/.cache/less/history";
    LESS = ''
      --RAW-CONTROL-CHARS \
      --ignore-case \
      --no-init \
      --quit-if-one-screen\
    '';
  };
}
