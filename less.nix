{ config, ... }:

{
  home-manager.users.avo
    .home.sessionVariables = with config.home-manager.users.avo; {
      LESSHISTFILE  = "${xdg.cacheHome}/less/history";
      LESS          = ''
                        --quit-if-one-screen \
                        --no-init \
                        --RAW-CONTROL-CHARS\
                      '';
    };
}
