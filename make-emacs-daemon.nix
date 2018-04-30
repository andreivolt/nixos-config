{ config, pkgs, name }:

{
  enable = true;
  wantedBy = [ "default.target" ];
  serviceConfig = {
    Type      = "forking";
    Restart   = "always";
    ExecStart = ''${pkgs.bash}/bin/bash -c 'source ${config.system.build.setEnvironment}; exec ${pkgs.emacs}/bin/emacs --daemon=${name} --eval "(+avo/${name})"' '';
    ExecStop  = "${pkgs.emacs}/bin/emacsclient -s ${name} --eval (kill-emacs)";
  };
}
