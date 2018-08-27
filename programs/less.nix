{ config, ... }:

{
  home-manager.users.avo
    .home.sessionVariables = with config.home-manager.users.avo; {
      PAGER = "less";
      LESSHISTFILE = "${xdg.cacheHome}/less/history";
      LESS = ''
        --RAW-CONTROL-CHARS \
        --ignore-case \
        --no-init \
        --quit-if-one-screen\
      '';
    };
}
