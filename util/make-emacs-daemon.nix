{ config, pkgs, name }:

{
  enable = true;
  wantedBy = [ "default.target" ];
  serviceConfig = {
    Type      = "forking";
    Restart   = "always";
    ExecStart = ''
                  ${pkgs.bash}/bin/bash -c '\
                    source ${config.system.build.setEnvironment};\
                    source ~/.nix-profile/etc/profile.d/hm-session-vars.sh;\
                    exec ${pkgs.emacs}/bin/emacs --daemon=${name} --eval "(+avo/${name})";\
                  '
                '';
    ExecStop  = ''
                  ${pkgs.emacs}/bin/emacsclient \
                    --socket-name ${name} \
                    --eval "(kill-emacs)";
                '';
  };
}
