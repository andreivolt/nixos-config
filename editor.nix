{ config, pkgs, ... }:

{
  systemd.user.services = {
    mainEmacsDaemon = let makeEmacsDaemon = import ./make-emacs-daemon.nix; in
      makeEmacsDaemon { inherit config pkgs; name = "main"; };

    mainEmacsClient =  {
      enable = true;
      serviceConfig = {
        Type      = "forking";
        Restart   = "always";
        ExecStart  = ''
                      ${pkgs.emacs}/bin/emacsclient \
                        --socket-name main
                    '';
        PIDFile      = "/run/main-emacs-client.pid";
        ExecStop     = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
    };
  };
}
